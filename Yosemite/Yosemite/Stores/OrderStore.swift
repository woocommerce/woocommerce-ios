import Foundation
import Networking
import Storage


// MARK: - OrderStore
//
public class OrderStore: Store {
    private let remote: OrdersRemote

    /// Shared private StorageType for use during the entire Orders sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = OrdersRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: OrderAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? OrderAction else {
            assertionFailure("OrderStore received an unsupported action")
            return
        }

        switch action {
        case .resetStoredOrders(let onCompletion):
            resetStoredOrders(onCompletion: onCompletion)
        case .retrieveOrder(let siteID, let orderID, let onCompletion):
            retrieveOrder(siteID: siteID, orderID: orderID, onCompletion: onCompletion)
        case .searchOrders(let siteID, let keyword, let pageNumber, let pageSize, let onCompletion):
            searchOrders(siteID: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .fetchFilteredOrders(let siteID, let statuses, let after, let before, let deleteAllBeforeSaving, let pageSize, let onCompletion):
            fetchFilteredOrders(siteID: siteID,
                                statuses: statuses,
                                after: after,
                                before: before,
                                deleteAllBeforeSaving: deleteAllBeforeSaving,
                                pageSize: pageSize,
                                onCompletion: onCompletion)
        case .synchronizeOrders(let siteID, let statuses, let after, let before, let pageNumber, let pageSize, let onCompletion):
            synchronizeOrders(siteID: siteID,
                              statuses: statuses,
                              after: after,
                              before: before,
                              pageNumber: pageNumber,
                              pageSize: pageSize,
                              onCompletion: onCompletion)
        case .updateOrderStatus(let siteID, let orderID, let statusKey, let onCompletion):
            updateOrder(siteID: siteID, orderID: orderID, status: statusKey, onCompletion: onCompletion)

        case let .updateOrder(siteID, order, fields, onCompletion):
            updateOrder(siteID: siteID, order: order, fields: fields, onCompletion: onCompletion)

        case let .createSimplePaymentsOrder(siteID, amount, taxable, onCompletion):
            createSimplePaymentsOrder(siteID: siteID, amount: amount, taxable: taxable, onCompletion: onCompletion)
        case let .createOrder(siteID, order, onCompletion):
            createOrder(siteID: siteID, order: order, onCompletion: onCompletion)

        case let .updateSimplePaymentsOrder(siteID, orderID, feeID, amount, taxable, orderNote, email, onCompletion):
            updateSimplePaymentsOrder(siteID: siteID,
                                      orderID: orderID,
                                      feeID: feeID,
                                      amount: amount,
                                      taxable: taxable,
                                      orderNote: orderNote,
                                      email: email,
                                      onCompletion: onCompletion)

        case let .updateOrderCustomerNote(siteID, order, onCompletion):
            updateOrder(siteID: siteID, order: order, customerNote: order.customerNote ?? String(), onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension OrderStore {

    /// Nukes all of the Stored Orders.
    ///
    func resetStoredOrders(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.Order.self)
        storage.saveIfNeeded()
        DDLogDebug("Orders deleted")

        onCompletion()
    }

    /// Searches all of the orders that contain a given Keyword.
    ///
    func searchOrders(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        remote.searchOrders(for: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize) { [weak self] (orders, error) in
            guard let orders = orders else {
                onCompletion(error)
                return
            }

            self?.upsertSearchResultsInBackground(keyword: keyword, readOnlyOrders: orders) {
                onCompletion(nil)
            }
        }
    }

    /// Performs a fetch for the first pages of a filtered list.
    ///
    /// If `deleteAllBeforeSaving` is true, all the orders will be deleted before saving any newly
    /// fetched `Order`. The deletion only happens once, regardless of the which fetch request
    /// finishes first.
    ///
    /// The orders will only be deleted if one of the executed `GET` requests succeed.
    ///
    /// - Parameter statuses The statuses to use for the filtered list. If this is not provided,
    ///                       only the all orders list will be fetched. See `OrderStatusEnum`
    ///                       for possible values.
    /// - Parameter after Limit response to resources published after a given ISO8601 compliant date.
    /// - Parameter before Limit response to resources published before a given ISO8601 compliant date.
    ///
    func fetchFilteredOrders(siteID: Int64,
                             statuses: [String]?,
                             after: Date?,
                             before: Date?,
                             deleteAllBeforeSaving: Bool,
                             pageSize: Int,
                             onCompletion: @escaping (TimeInterval, Error?) -> Void) {

        let pageNumber = OrdersRemote.Defaults.pageNumber

        // Synchronous variables.
        //
        // The variables `fetchErrors` and `hasDeletedAllOrders` should only be accessed
        // **inside** the `serialQueue` (e.g. `serialQueue.async()`). The only exception is in
        // the `group.notify()` call below which only _reads_ `fetchErrors` and all the _writes_
        // have finished.
        var fetchErrors = [Error]()
        var hasDeletedAllOrders = false
        let serialQueue = DispatchQueue(label: "orders_sync", qos: .userInitiated)
        let startTime = Date()

        // Delete all the orders if we haven't yet.
        // This should only be called inside the `serialQueue` block.
        let deleteAllOrdersOnce = { [weak self] in
            guard hasDeletedAllOrders == false else {
                return
            }

            // Use the main thread because `resetStoredOrders` uses `viewStorage`.
            DispatchQueue.main.sync { [weak self] in
                self?.resetStoredOrders { }
            }

            hasDeletedAllOrders = true
        }

        // The handler for fetching requests.
        let loadAllOrders: ([String]?, @escaping (() -> Void)) -> Void = { [weak self] statuses, completion in
            guard let self = self else {
                return
            }
            self.remote.loadAllOrders(for: siteID,
                                         statuses: statuses,
                                         after: after,
                                         before: before,
                                         pageNumber: pageNumber,
                                         pageSize: pageSize) { [weak self] result in
                guard let self = self else {
                    return
                }
                serialQueue.async { [weak self] in
                    guard let self = self else {
                        completion()
                        return
                    }

                    switch result {
                    case .success(let orders):
                        if deleteAllBeforeSaving {
                            deleteAllOrdersOnce()
                        }

                        self.upsertStoredOrdersInBackground(readOnlyOrders: orders, onCompletion: completion)
                    case .failure(let error):
                        fetchErrors.append(error)
                        completion()
                    }
                }
            }
        }

        // Perform fetch and wait to finish before calling `onCompletion`.
        let group = DispatchGroup()

        group.enter()
        if let statuses = statuses {
            loadAllOrders(statuses) {
                group.leave()
            }
        }
        else {
            loadAllOrders([OrdersRemote.Defaults.statusAny]) {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            onCompletion(Date().timeIntervalSince(startTime), fetchErrors.first)
        }
    }

    /// Retrieves the orders associated with a given Site ID (if any!).
    ///
    func synchronizeOrders(siteID: Int64,
                           statuses: [String]?,
                           after: Date?,
                           before: Date?,
                           pageNumber: Int,
                           pageSize: Int,
                           onCompletion: @escaping (TimeInterval, Error?) -> Void) {
        let startTime = Date()
        remote.loadAllOrders(for: siteID,
                             statuses: statuses,
                             after: after,
                             before: before,
                             pageNumber: pageNumber,
                             pageSize: pageSize) { [weak self] result in
            switch result {
            case .success(let orders):
                self?.upsertStoredOrdersInBackground(readOnlyOrders: orders) {
                    onCompletion(Date().timeIntervalSince(startTime), nil)
                }
            case .failure(let error):
                onCompletion(Date().timeIntervalSince(startTime), error)
            }
        }
    }

    /// Retrieves a specific order associated with a given Site ID (if any!).
    ///
    func retrieveOrder(siteID: Int64, orderID: Int64, onCompletion: @escaping (Order?, Error?) -> Void) {
        remote.loadOrder(for: siteID, orderID: orderID) { [weak self] (order, error) in
            guard let order = order else {
                if case NetworkError.notFound? = error {
                    self?.deleteStoredOrder(siteID: siteID, orderID: orderID)
                }
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredOrdersInBackground(readOnlyOrders: [order]) {
                onCompletion(order, nil)
            }
        }
    }

    /// Creates a simple payments order with a specific amount value and no tax.
    ///
    func createSimplePaymentsOrder(siteID: Int64, amount: String, taxable: Bool, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        let order = OrderFactory.simplePaymentsOrder(amount: amount, taxable: taxable)
        remote.createOrder(siteID: siteID, order: order, fields: [.feeLines]) { [weak self] result in
            switch result {
            case .success(let order):
                self?.upsertStoredOrdersInBackground(readOnlyOrders: [order], onCompletion: {
                    onCompletion(result)
                })
            case .failure:
                onCompletion(result)
            }
        }
    }

    /// Updates a simple payment order with the specified values.
    ///
    func updateSimplePaymentsOrder(siteID: Int64,
                                   orderID: Int64,
                                   feeID: Int64,
                                   amount: String,
                                   taxable: Bool,
                                   orderNote: String?,
                                   email: String?,
                                   onCompletion: @escaping (Result<Order, Error>) -> Void) {

        // Recreate the original order
        let originalOrder = OrderFactory.simplePaymentsOrder(amount: amount, taxable: taxable)

        // Create updated fields
        let newFee = OrderFactory.simplePaymentFee(feeID: feeID, amount: amount, taxable: taxable)
        let newBillingAddress = Address(firstName: "",
                                        lastName: "",
                                        company: nil,
                                        address1: "",
                                        address2: nil,
                                        city: "",
                                        state: "",
                                        postcode: "",
                                        country: "",
                                        phone: nil,
                                        email: email)

        // Set new fields
        let updatedOrder = originalOrder.copy(orderID: orderID, customerNote: orderNote, billingAddress: newBillingAddress, fees: [newFee])
        let updateFields: [OrderUpdateField] = [.customerNote, .billingAddress, .fees]

        updateOrder(siteID: siteID, order: updatedOrder, fields: updateFields, onCompletion: onCompletion)
    }

    /// Creates a manual order with the provided order details.
    ///
    func createOrder(siteID: Int64, order: Order, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        remote.createOrder(siteID: siteID, order: order, fields: []) { [weak self] result in
            switch result {
            case .success(let order):
                self?.upsertStoredOrdersInBackground(readOnlyOrders: [order], onCompletion: {
                    onCompletion(result)
                })
            case .failure:
                onCompletion(result)
            }
        }
    }

    /// Updates an Order with the specified Status.
    ///
    func updateOrder(siteID: Int64, orderID: Int64, status: OrderStatusEnum, onCompletion: @escaping (Error?) -> Void) {
        /// Optimistically update the Status
        let oldStatus = updateOrderStatus(siteID: siteID, orderID: orderID, statusKey: status)

        remote.updateOrder(from: siteID, orderID: orderID, statusKey: status) { [weak self] (_, error) in
            guard let error = error else {
                // NOTE: We're *not* actually updating the whole entity here. Reason: Prevent UI inconsistencies!!
                onCompletion(nil)
                return
            }

            /// Revert Optimistic Update
            self?.updateOrderStatus(siteID: siteID, orderID: orderID, statusKey: oldStatus)
            onCompletion(error)
        }
    }

    /// Updates the specified fields from an order.
    ///
    func updateOrder(siteID: Int64, order: Order, fields: [OrderUpdateField], onCompletion: @escaping (Result<Order, Error>) -> Void) {
        remote.updateOrder(from: siteID, order: order, fields: fields) { [weak self] result in
            switch result {
            case .success(let order):
                self?.upsertStoredOrdersInBackground(readOnlyOrders: [order], onCompletion: {
                    onCompletion(result)
                })
            case .failure:
                onCompletion(result)
            }
        }
    }

    /// Updates the order customer note field from an order.
    ///
    func updateOrder(siteID: Int64, order: Order, customerNote: String, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        /// Optimistically update the customer note
        let oldCustomerNote = updateOrderCustomerNote(siteID: siteID, orderID: order.orderID, customerNote: customerNote)

        remote.updateOrder(from: siteID, order: order, fields: [.customerNote]) { [weak self] result in
            switch result {
            case .success(let order):
                self?.upsertStoredOrdersInBackground(readOnlyOrders: [order], onCompletion: {
                    onCompletion(result)
                })
            case .failure:
                /// Revert Optimistic Update
                self?.updateOrderCustomerNote(siteID: siteID, orderID: order.orderID, customerNote: oldCustomerNote)
                onCompletion(result)
            }
        }
    }
}


// MARK: - Storage
//
extension OrderStore {

    /// Deletes any Storage.Order with the specified OrderID
    ///
    func deleteStoredOrder(siteID: Int64, orderID: Int64) {
        let storage = storageManager.viewStorage
        guard let order = storage.loadOrder(siteID: siteID, orderID: orderID) else {
            return
        }

        storage.deleteObject(order)
        storage.saveIfNeeded()
    }

    /// Updates the Status of the specified Order, as requested.
    ///
    /// - Returns: Status, prior to performing the Update OP.
    ///
    @discardableResult
    func updateOrderStatus(siteID: Int64, orderID: Int64, statusKey: OrderStatusEnum) -> OrderStatusEnum {
        let storage = storageManager.viewStorage
        guard let order = storage.loadOrder(siteID: siteID, orderID: orderID) else {
            return statusKey
        }

        let oldStatus = order.statusKey
        order.statusKey = statusKey.rawValue
        storage.saveIfNeeded()

        return OrderStatusEnum(rawValue: oldStatus)
    }

    /// Updates the order customer note of the specified Order, as requested.
    ///
    /// - Returns: Order customer note, prior to performing the Update OP.
    ///
    @discardableResult
    func updateOrderCustomerNote(siteID: Int64, orderID: Int64, customerNote: String?) -> String? {
        let storage = storageManager.viewStorage
        guard let order = storage.loadOrder(siteID: siteID, orderID: orderID) else {
            return customerNote
        }

        let oldCustomerNote = order.customerNote
        order.customerNote = customerNote
        storage.saveIfNeeded()

        return oldCustomerNote
    }
}


// MARK: - Unit Testing Helpers
//
extension OrderStore {

    /// Unit Testing Helper: Updates or Inserts the specified ReadOnly Order in a given Storage Layer.
    ///
    func upsertStoredOrder(readOnlyOrder: Networking.Order, insertingSearchResults: Bool = false, in storage: StorageType) {
        upsertStoredOrders(readOnlyOrders: [readOnlyOrder], insertingSearchResults: insertingSearchResults, in: storage)
    }

    /// Unit Testing Helper: Updates or Inserts a given Search Results page
    ///
    func upsertStoredResults(keyword: String, readOnlyOrder: Networking.Order, in storage: StorageType) {
        upsertStoredResults(keyword: keyword, readOnlyOrders: [readOnlyOrder], in: storage)
    }
}


// MARK: - Storage: Search Results
//
private extension OrderStore {

    /// Upserts the Orders, and associates them to the SearchResults Entity (in Background)
    ///
    private func upsertSearchResultsInBackground(keyword: String, readOnlyOrders: [Networking.Order], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self = self else {
                return
            }
            self.upsertStoredOrders(readOnlyOrders: readOnlyOrders, insertingSearchResults: true, in: derivedStorage)
            self.upsertStoredResults(keyword: keyword, readOnlyOrders: readOnlyOrders, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Upserts the Orders, and associates them to the Search Results Entity (in the specified Storage)
    ///
    private func upsertStoredResults(keyword: String, readOnlyOrders: [Networking.Order], in storage: StorageType) {
        let searchResults = storage.loadOrderSearchResults(keyword: keyword) ?? storage.insertNewObject(ofType: Storage.OrderSearchResults.self)
        searchResults.keyword = keyword

        for readOnlyOrder in readOnlyOrders {
            guard let storedOrder = storage.loadOrder(siteID: readOnlyOrder.siteID, orderID: readOnlyOrder.orderID) else {
                continue
            }

            storedOrder.addToSearchResults(searchResults)
        }
    }
}


// MARK: - Storage: Orders
//
private extension OrderStore {

    /// Updates (OR Inserts) the specified ReadOnly Order Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    private func upsertStoredOrdersInBackground(readOnlyOrders: [Networking.Order], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self = self else {
                return
            }
            self.upsertStoredOrders(readOnlyOrders: readOnlyOrders, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly Order Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyOrders: Remote Orders to be persisted.
    ///     - insertingSearchResults: Indicates if the "Newly Inserted Entities" should be marked as "Search Results Only"
    ///     - storage: Where we should save all the things!
    ///
    private func upsertStoredOrders(readOnlyOrders: [Networking.Order],
                                    insertingSearchResults: Bool = false,
                                    in storage: StorageType) {
        let useCase = OrdersUpsertUseCase(storage: storage)
        useCase.upsert(readOnlyOrders, insertingSearchResults: insertingSearchResults)
    }
}
