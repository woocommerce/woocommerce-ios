import Combine
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
        case let .fetchFilteredOrders(siteID, statuses, after, before, modifiedAfter, deleteAllBeforeSaving, pageSize, onCompletion):
            fetchFilteredOrders(siteID: siteID,
                                statuses: statuses,
                                after: after,
                                before: before,
                                modifiedAfter: modifiedAfter,
                                deleteAllBeforeSaving: deleteAllBeforeSaving,
                                pageSize: pageSize,
                                onCompletion: onCompletion)
        case let .synchronizeOrders(siteID, statuses, after, before, modifiedAfter, pageNumber, pageSize, onCompletion):
            synchronizeOrders(siteID: siteID,
                              statuses: statuses,
                              after: after,
                              before: before,
                              modifiedAfter: modifiedAfter,
                              pageNumber: pageNumber,
                              pageSize: pageSize,
                              onCompletion: onCompletion)
        case .updateOrderStatus(let siteID, let orderID, let statusKey, let onCompletion):
            updateOrder(siteID: siteID, orderID: orderID, status: statusKey, onCompletion: onCompletion)

        case let .updateOrder(siteID, order, fields, onCompletion):
            updateOrder(siteID: siteID, order: order, fields: fields, onCompletion: onCompletion)
        case let .updateOrderOptimistically(siteID, order, fields, onCompletion):
            updateOrderOptimistically(siteID: siteID, order: order, fields: fields, onCompletion: onCompletion)
        case let .createSimplePaymentsOrder(siteID, status, amount, taxable, onCompletion):
            createSimplePaymentsOrder(siteID: siteID, status: status, amount: amount, taxable: taxable, onCompletion: onCompletion)
        case let .createOrder(siteID, order, onCompletion):
            createOrder(siteID: siteID, order: order, onCompletion: onCompletion)

        case let .updateSimplePaymentsOrder(siteID, orderID, feeID, status, amount, taxable, orderNote, email, onCompletion):
            updateSimplePaymentsOrder(siteID: siteID,
                                      orderID: orderID,
                                      feeID: feeID,
                                      status: status,
                                      amount: amount,
                                      taxable: taxable,
                                      orderNote: orderNote,
                                      email: email,
                                      onCompletion: onCompletion)
        case let .markOrderAsPaidLocally(siteID, orderID, datePaid, onCompletion):
            markOrderAsPaidLocally(siteID: siteID, orderID: orderID, datePaid: datePaid, onCompletion: onCompletion)
        case let .deleteOrder(siteID, order, deletePermanently, onCompletion):
            deleteOrder(siteID: siteID, order: order, deletePermanently: deletePermanently, onCompletion: onCompletion)
        case let .observeInsertedOrders(siteID, completion):
            observeInsertedOrders(siteID: siteID, completion: completion)
        case let .checkIfStoreHasOrders(siteID, completion):
            checkIfStoreHasOrders(siteID: siteID, onCompletion: completion)
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
    /// - Parameters:
    ///     - statuses: The statuses to use for the filtered list. If this is not provided,
    ///                       only the all orders list will be fetched. See `OrderStatusEnum`
    ///                       for possible values.
    ///     - after: Limit response to resources published after a given ISO8601 compliant date.
    ///     - before: Limit response to resources published before a given ISO8601 compliant date.
    ///     - modifiedAfter: Limit response to resources modified after a given ISO8601 compliant date.
    ///
    func fetchFilteredOrders(siteID: Int64,
                             statuses: [String]?,
                             after: Date?,
                             before: Date?,
                             modifiedAfter: Date?,
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
                                      modifiedAfter: modifiedAfter,
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
                           modifiedAfter: Date?,
                           pageNumber: Int,
                           pageSize: Int,
                           onCompletion: @escaping (TimeInterval, Error?) -> Void) {
        let startTime = Date()
        remote.loadAllOrders(for: siteID,
                             statuses: statuses,
                             after: after,
                             before: before,
                             modifiedAfter: modifiedAfter,
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

    /// Checks if the store already has any orders.
    ///
    func checkIfStoreHasOrders(siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        // Check for locally stored products first.
        let storage = storageManager.viewStorage
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        if storage.firstObject(ofType: StorageOrder.self, matching: predicate) != nil {
            return onCompletion(.success(true))
        }

        // If there are no locally stored orders, then check remote.
        remote.loadAllOrders(for: siteID, pageNumber: Default.firstPageNumber, pageSize: 1) { result in
            switch result {
            case .success(let orders):
                onCompletion(.success(orders.isEmpty == false))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Retrieves a specific order associated with a given Site ID (if any!).
    ///
    func retrieveOrder(siteID: Int64, orderID: Int64, onCompletion: @escaping (Order?, Error?) -> Void) {
        // Check first if the order exists in storage. If it doesn't, fetch it from remote.
        let storage = storageManager.viewStorage
        guard let storedOrder = storage.loadOrder(siteID: siteID, orderID: orderID)?.toReadOnly() else {
            return loadOrderFromRemote(siteID: siteID, orderID: orderID, onCompletion: onCompletion)
        }

        Task {
            // If the order exists in storage, fetch the last modified date to see if it has been updated remotely.
            let dateModified = try? await remote.fetchDateModified(for: siteID, orderID: orderID)

            // If the stored order is up to date with remote, return it.
            // Otherwise, fetch the updated order from remote.
            await MainActor.run {
                guard dateModified == storedOrder.dateModified else {
                    return loadOrderFromRemote(siteID: siteID, orderID: orderID, onCompletion: onCompletion)
                }
                onCompletion(storedOrder, nil)
            }
        }
    }

    /// Loads a specific order associated with a given Site ID from remote.
    ///
    private func loadOrderFromRemote(siteID: Int64, orderID: Int64, onCompletion: @escaping (Order?, Error?) -> Void) {
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
    func createSimplePaymentsOrder(siteID: Int64,
                                   status: OrderStatusEnum,
                                   amount: String,
                                   taxable: Bool,
                                   onCompletion: @escaping (Result<Order, Error>) -> Void) {
        let order = OrderFactory.simplePaymentsOrder(status: status, amount: amount, taxable: taxable)
        remote.createOrder(siteID: siteID, order: order, fields: [.status, .feeLines]) { [weak self] result in
            switch result {
            case .success(let order):
                // Auto-draft orders are temporary and should not be stored
                guard order.status != .autoDraft else {
                    return onCompletion(result)
                }

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
                                   status: OrderStatusEnum,
                                   amount: String,
                                   taxable: Bool,
                                   orderNote: String?,
                                   email: String?,
                                   onCompletion: @escaping (Result<Order, Error>) -> Void) {

        // Recreate the original order
        let originalOrder = OrderFactory.simplePaymentsOrder(status: status, amount: amount, taxable: taxable)

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
        let updateFields: [OrderUpdateField] = [.customerNote, .billingAddress, .fees, .status]

        updateOrder(siteID: siteID, order: updatedOrder, fields: updateFields, onCompletion: onCompletion)
    }

    /// Creates a manual order with the provided order details.
    ///
    func createOrder(siteID: Int64, order: Order, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        let fields: [OrdersRemote.CreateOrderField] = [.status,
                                                       .items,
                                                       .billingAddress,
                                                       .shippingAddress,
                                                       .shippingLines,
                                                       .feeLines,
                                                       .couponLines,
                                                       .customerNote]
        remote.createOrder(siteID: siteID,
                           order: order,
                           fields: fields) { [weak self] result in
            switch result {
            case .success(let order):
                // Auto-draft orders are temporary and should not be stored
                guard order.status != .autoDraft else {
                    return onCompletion(result)
                }
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

        remote.updateOrder(from: siteID, orderID: orderID, statusKey: status) { [weak self] (order, error) in
            guard let error = error else {
                if let order = order {
                    self?.upsertStoredOrder(readOnlyOrder: order)
                }
                return onCompletion(nil)
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
                // Auto-draft orders are temporary and should not be stored
                guard order.status != .autoDraft else {
                    return onCompletion(result)
                }
                self?.upsertStoredOrdersInBackground(readOnlyOrders: [order], onCompletion: {
                    onCompletion(result)
                })
            case .failure:
                onCompletion(result)
            }
        }
    }

    /// Updates the specified fields from an order optimistically.
    ///
    /// Updates will be reverted in case of failure.
    ///
    func updateOrderOptimistically(siteID: Int64, order: Order, fields: [OrderUpdateField], onCompletion: @escaping (Result<Order, Error>) -> Void) {
        // Optimistically update the stored order.
        let backupOrder = upsertStoredOrder(readOnlyOrder: order)

        remote.updateOrder(from: siteID, order: order, fields: fields) { [weak self] result in
            guard case .failure = result else {
                onCompletion(.success(order))
                return
            }

            /// Revert optimistic update.
            ///
            /// If the backup order is equal to the given order means that the order
            /// didn't exist locally. So, we have to delete the stored order as workaround.
            /// Otherwise, we have to revert the updated fields.
            if order == backupOrder {
                self?.deleteStoredOrder(siteID: siteID, orderID: order.orderID)
            } else {
                self?.upsertStoredOrder(readOnlyOrder: backupOrder)
            }
            onCompletion(result)
        }
    }

    /// Updates an order to be considered as paid locally, for use cases where the payment is captured in the
    /// app to prevent from multiple charging for the same order after subsequent failures (e.g. Interac in Canada).
    ///
    func markOrderAsPaidLocally(siteID: Int64, orderID: Int64, datePaid: Date, onCompletion: (Result<Order, Error>) -> Void) {
        let storage = storageManager.viewStorage
        guard let order = storage.loadOrder(siteID: siteID, orderID: orderID) else {
            return onCompletion(.failure(MarkOrderAsPaidLocallyError.orderNotFoundInStorage))
        }
        order.datePaid = datePaid
        order.statusKey = OrderStatusEnum.processing.rawValue
        storage.saveIfNeeded()
        onCompletion(.success(order.toReadOnly()))
    }

    /// Deletes a given order.
    ///
    func deleteOrder(siteID: Int64, order: Order, deletePermanently: Bool, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        // Optimistically delete the order from storage
        deleteStoredOrder(siteID: siteID, orderID: order.orderID)

        remote.deleteOrder(for: siteID, orderID: order.orderID, force: deletePermanently) { [weak self] result in
            switch result {
            case .success:
                onCompletion(result)
            case .failure:
                // Revert optimistic deletion unless the order is an auto-draft (shouldn't be stored)
                guard order.status != .autoDraft else {
                    return onCompletion(result)
                }
                self?.upsertStoredOrdersInBackground(readOnlyOrders: [order], onCompletion: {
                    onCompletion(result)
                })
            }
        }
    }

    func observeInsertedOrders(siteID: Int64, completion: (AnyPublisher<[Order], Never>) -> Void) {
        completion(
            NotificationCenter.default
                .publisher(for: .NSManagedObjectContextObjectsDidChange, object: storageManager.viewStorage)
                .map { notification -> [Order] in
                    guard let note = ManagedObjectsDidChangeNotification(notification: notification) else {
                        return []
                    }

                    return note.insertedObjects.compactMap { ($0 as? StorageOrder)?.toReadOnly() }
                }
                .map { orders in
                    orders.filter { $0.siteID == siteID }
                }
                .filter { $0.isEmpty == false }
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
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
    /// Updates or inserts the specified ReadOnly Order Entity.
    ///
    /// - Returns: The updated order, prior to performing the update operation or the given order when
    /// the order doesn't exist locally.
    ///
    @discardableResult
    func upsertStoredOrder(readOnlyOrder: Networking.Order) -> Networking.Order {
        let storageOrder = storageManager.viewStorage.loadOrder(siteID: readOnlyOrder.siteID, orderID: readOnlyOrder.orderID)
        let oldReadOnlyOrder = storageOrder?.toReadOnly()

        upsertStoredOrders(readOnlyOrders: [readOnlyOrder], in: storageManager.viewStorage)

        if storageOrder == nil {
            DDLogWarn("⚠️ Unable to retrieve stored order with ID \(readOnlyOrder.orderID) to be updated - A new order has been stored as a workaround")
        }

        return oldReadOnlyOrder ?? readOnlyOrder
    }

    /// Upserts the Orders, and associates them to the SearchResults Entity (in Background)
    ///
    func upsertSearchResultsInBackground(keyword: String, readOnlyOrders: [Networking.Order], onCompletion: @escaping () -> Void) {
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
    func upsertStoredResults(keyword: String, readOnlyOrders: [Networking.Order], in storage: StorageType) {
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

extension OrderStore {
    enum MarkOrderAsPaidLocallyError: Error {
        case orderNotFoundInStorage
    }
}
