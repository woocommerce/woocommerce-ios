import Foundation
import Networking
import Storage


// MARK: - OrderStore
//
public class OrderStore: Store {

    /// Shared private StorageType for use during the entire Orders sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

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
        case .fetchFilteredAndAllOrders(let siteID, let statusKey, let deleteAllBeforeSaving, let pageSize, let onCompletion):
            fetchFilteredAndAllOrders(siteID: siteID,
                                      statusKey: statusKey,
                                      deleteAllBeforeSaving: deleteAllBeforeSaving,
                                      pageSize: pageSize,
                                      onCompletion: onCompletion)
        case .synchronizeOrders(let siteID, let statusKey, let pageNumber, let pageSize, let onCompletion):
            synchronizeOrders(siteID: siteID, statusKey: statusKey, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .updateOrder(let siteID, let orderID, let statusKey, let onCompletion):
            updateOrder(siteID: siteID, orderID: orderID, statusKey: statusKey, onCompletion: onCompletion)
        case .countProcessingOrders(let siteID, let onCompletion):
            countProcessingOrders(siteID: siteID, onCompletion: onCompletion)
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
        let remote = OrdersRemote(network: network)

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

    /// Performs a dual fetch for the first pages of a filtered list and the all orders list.
    ///
    /// If `deleteAllBeforeSaving` is true, all the orders will be deleted before saving any newly
    /// fetched `Order`. The deletion only happens once, regardless of the which fetch request
    /// finishes first.
    ///
    /// The orders will only be deleted if one of the executed `GET` requests succeed.
    ///
    /// - Parameter statusKey The status to use for the filtered list. If this is not provided,
    ///                       only the all orders list will be fetched. See `OrderStatusEnum`
    ///                       for possible values.
    ///
    func fetchFilteredAndAllOrders(siteID: Int64,
                                   statusKey: String?,
                                   deleteAllBeforeSaving: Bool,
                                   pageSize: Int,
                                   onCompletion: @escaping (Error?) -> Void) {

        let remote = OrdersRemote(network: network)
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

        // Delete all the orders if we haven't yet.
        // This should only be called inside a `serialQueue` block.
        let deleteAllOrdersOnce = {
            guard hasDeletedAllOrders == false else {
                return
            }

            // Use the main thread because `resetStoredOrders` uses `viewStorage`.
            DispatchQueue.main.sync { [weak self] in
                self?.resetStoredOrders { }
            }

            hasDeletedAllOrders = true
        }

        // The handler for both dual fetch requests.
        let loadAllOrders: (String?, @escaping (() -> Void)) -> Void = { statusKey, completion in
            remote.loadAllOrders(for: siteID, statusKey: statusKey, pageNumber: pageNumber, pageSize: pageSize) { orders, error in
                serialQueue.async { [weak self] in
                    guard let self = self else {
                        completion()
                        return
                    }

                    if let orders = orders {
                        if deleteAllBeforeSaving {
                            deleteAllOrdersOnce()
                        }

                        self.upsertStoredOrdersInBackground(readOnlyOrders: orders, onCompletion: completion)
                    } else if let error = error {
                        fetchErrors.append(error)
                        completion()
                    } else {
                        // This shouldn't happen but we're adding it just in case.
                        completion()
                    }
                }
            }
        }

        // Perform dual fetch and wait for both of them to finish before calling `onCompletion`.
        let group = DispatchGroup()

        if let statusKey = statusKey {
            group.enter()
            loadAllOrders(statusKey) {
                group.leave()
            }
        }

        group.enter()
        loadAllOrders(OrdersRemote.Defaults.statusAny) {
            group.leave()
        }

        group.notify(queue: .main) {
            onCompletion(fetchErrors.first)
        }
    }

    /// Retrieves the orders associated with a given Site ID (if any!).
    ///
    func synchronizeOrders(siteID: Int64, statusKey: String?, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = OrdersRemote(network: network)

        remote.loadAllOrders(for: siteID, statusKey: statusKey, pageNumber: pageNumber, pageSize: pageSize) { [weak self] (orders, error) in
            guard let orders = orders else {
                onCompletion(error)
                return
            }

            self?.upsertStoredOrdersInBackground(readOnlyOrders: orders) {
                onCompletion(nil)
            }
        }
    }

    /// Retrieves a specific order associated with a given Site ID (if any!).
    ///
    func retrieveOrder(siteID: Int64, orderID: Int64, onCompletion: @escaping (Order?, Error?) -> Void) {
        let remote = OrdersRemote(network: network)

        remote.loadOrder(for: siteID, orderID: orderID) { [weak self] (order, error) in
            guard let order = order else {
                if case NetworkError.notFound? = error {
                    self?.deleteStoredOrder(orderID: orderID)
                }
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredOrdersInBackground(readOnlyOrders: [order]) {
                onCompletion(order, nil)
            }
        }
    }

    /// Updates an Order with the specified Status.
    ///
    func updateOrder(siteID: Int64, orderID: Int64, statusKey: String, onCompletion: @escaping (Error?) -> Void) {
        /// Optimistically update the Status
        let oldStatus = updateOrderStatus(orderID: orderID, statusKey: statusKey)

        let remote = OrdersRemote(network: network)
        remote.updateOrder(from: siteID, orderID: orderID, statusKey: statusKey) { [weak self] (_, error) in
            guard let error = error else {
                // NOTE: We're *not* actually updating the whole entity here. Reason: Prevent UI inconsistencies!!
                onCompletion(nil)
                return
            }

            /// Revert Optimistic Update
            self?.updateOrderStatus(orderID: orderID, statusKey: oldStatus)
            onCompletion(error)
        }
    }

    func countProcessingOrders(siteID: Int64, onCompletion: @escaping (OrderCount?, Error?) -> Void) {
        let remote = OrdersRemote(network: network)

        let status = OrderStatusEnum.processing.rawValue

        remote.countOrders(for: siteID, statusKey: status) { [weak self] (orderCount, error) in
            guard let orderCount = orderCount else {
                onCompletion(nil, error)
                return
            }

            self?.upsertOrderCountInBackground(siteID: siteID, readOnlyOrderCount: orderCount) {
                onCompletion(orderCount, nil)
            }
        }
    }
}


// MARK: - Storage
//
extension OrderStore {

    /// Deletes any Storage.Order with the specified OrderID
    ///
    func deleteStoredOrder(orderID: Int64) {
        let storage = storageManager.viewStorage
        guard let order = storage.loadOrder(orderID: orderID) else {
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
    func updateOrderStatus(orderID: Int64, statusKey: String) -> String {
        let storage = storageManager.viewStorage
        guard let order = storage.loadOrder(orderID: orderID) else {
            return statusKey
        }

        let oldStatus = order.statusKey
        order.statusKey = statusKey
        storage.saveIfNeeded()

        return oldStatus
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
        derivedStorage.perform {
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
            guard let storedOrder = storage.loadOrder(orderID: readOnlyOrder.orderID) else {
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
        derivedStorage.perform {
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

        for readOnlyOrder in readOnlyOrders {
            let storageOrder = storage.loadOrder(orderID: readOnlyOrder.orderID) ?? storage.insertNewObject(ofType: Storage.Order.self)
            storageOrder.update(with: readOnlyOrder)

            // Are we caching Search Results? Did this order exist before?
            storageOrder.exclusiveForSearch = insertingSearchResults && (storageOrder.isInserted || storageOrder.exclusiveForSearch)

            handleOrderItems(readOnlyOrder, storageOrder, storage)
            handleOrderCoupons(readOnlyOrder, storageOrder, storage)
            handleOrderShippingLines(readOnlyOrder, storageOrder, storage)
            handleOrderRefundsCondensed(readOnlyOrder, storageOrder, storage)
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's items using the provided read-only Order's items
    ///
    private func handleOrderItems(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        var storageItem: Storage.OrderItem
        let siteID = readOnlyOrder.siteID
        let orderID = readOnlyOrder.orderID

        // Upsert the items from the read-only order
        for readOnlyItem in readOnlyOrder.items {
            if let existingStorageItem = storage.loadOrderItem(siteID: siteID, orderID: orderID, itemID: readOnlyItem.itemID) {
                existingStorageItem.update(with: readOnlyItem)
                storageItem = existingStorageItem
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.OrderItem.self)
                newStorageItem.update(with: readOnlyItem)
                storageOrder.addToItems(newStorageItem)
                storageItem = newStorageItem
            }

            handleOrderItemTaxes(readOnlyItem, storageItem, storage)
        }

        // Now, remove any objects that exist in storageOrder.items but not in readOnlyOrder.items
        storageOrder.items?.forEach { storageItem in
            if readOnlyOrder.items.first(where: { $0.itemID == storageItem.itemID } ) == nil {
                storageOrder.removeFromItems(storageItem)
                storage.deleteObject(storageItem)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrderItem's taxes using the provided read-only OrderItem
    ///
    private func handleOrderItemTaxes(_ readOnlyItem: Networking.OrderItem, _ storageItem: Storage.OrderItem, _ storage: StorageType) {
        let itemID = readOnlyItem.itemID

        // Upsert the taxes from the read-only orderItem
        for readOnlyTax in readOnlyItem.taxes {
            if let existingStorageTax = storage.loadOrderItemTax(itemID: itemID, taxID: readOnlyTax.taxID) {
                existingStorageTax.update(with: readOnlyTax)
            } else {
                let newStorageTax = storage.insertNewObject(ofType: Storage.OrderItemTax.self)
                newStorageTax.update(with: readOnlyTax)
                storageItem.addToTaxes(newStorageTax)
            }
        }

        // Now, remove any objects that exist in storageOrderItem.taxes but not in readOnlyOrderItem.taxes
        storageItem.taxes?.forEach { storageTax in
            if readOnlyItem.taxes.first(where: { $0.taxID == storageTax.taxID } ) == nil {
                storageItem.removeFromTaxes(storageTax)
                storage.deleteObject(storageTax)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's coupons using the provided read-only Order's coupons
    ///
    private func handleOrderCoupons(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Upsert the coupons from the read-only order
        for readOnlyCoupon in readOnlyOrder.coupons {
            if let existingStorageCoupon = storage.loadOrderCoupon(couponID: readOnlyCoupon.couponID) {
                existingStorageCoupon.update(with: readOnlyCoupon)
            } else {
                let newStorageCoupon = storage.insertNewObject(ofType: Storage.OrderCoupon.self)
                newStorageCoupon.update(with: readOnlyCoupon)
                storageOrder.addToCoupons(newStorageCoupon)
            }
        }

        // Now, remove any objects that exist in storageOrder.coupons but not in readOnlyOrder.coupons
        storageOrder.coupons?.forEach { storageCoupon in
            if readOnlyOrder.coupons.first(where: { $0.couponID == storageCoupon.couponID } ) == nil {
                storageOrder.removeFromCoupons(storageCoupon)
                storage.deleteObject(storageCoupon)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's condensed refunds using the provided read-only Order's OrderRefundCondensed
    ///
    private func handleOrderRefundsCondensed(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Upsert the refunds from the read-only order
        for readOnlyRefund in readOnlyOrder.refunds {
            if let existingStorageRefund = storage.loadOrderRefundCondensed(refundID: readOnlyRefund.refundID) {
                existingStorageRefund.update(with: readOnlyRefund)
            } else {
                let newStorageRefund = storage.insertNewObject(ofType: Storage.OrderRefundCondensed.self)
                newStorageRefund.update(with: readOnlyRefund)
                storageOrder.addToRefunds(newStorageRefund)
            }
        }

        // Now, remove any objects that exist in storageOrder.OrderRefundCondensed but not in readOnlyOrder.OrderRefundCondensed
        storageOrder.refunds?.forEach { storageRefunds in
            if readOnlyOrder.refunds.first(where: { $0.refundID == storageRefunds.refundID } ) == nil {
                storageOrder.removeFromRefunds(storageRefunds)
                storage.deleteObject(storageRefunds)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's shipping lines using the provided read-only Order's shippingLine
    ///
    private func handleOrderShippingLines(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Upsert the shipping lines from the read-only order
        for readOnlyShippingLine in readOnlyOrder.shippingLines {
            if let existingStorageShippingLine = storage.loadShippingLine(shippingID: readOnlyShippingLine.shippingID) {
                existingStorageShippingLine.update(with: readOnlyShippingLine)
            } else {
                let newStorageShippingLine = storage.insertNewObject(ofType: Storage.ShippingLine.self)
                newStorageShippingLine.update(with: readOnlyShippingLine)
                storageOrder.addToShippingLines(newStorageShippingLine)
            }
        }

        // Now, remove any objects that exist in storageOrder.shippingLines but not in readOnlyOrder.shippingLines
        storageOrder.shippingLines?.forEach { storageShippingLine in
            if readOnlyOrder.shippingLines.first(where: { $0.shippingID == storageShippingLine.shippingID } ) == nil {
                storageOrder.removeFromShippingLines(storageShippingLine)
                storage.deleteObject(storageShippingLine)
            }
        }
    }
}


// MARK: - Storage: Order count
//
private extension OrderStore {

    /// Updates the stored OrderCount with the new OrderCount fetched from the remote
    ///
    private func upsertOrderCountInBackground(siteID: Int64, readOnlyOrderCount: Networking.OrderCount, onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.updateOrderCountResults(siteID: siteID, readOnlyOrderCount: readOnlyOrderCount, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    private func updateOrderCountResults(siteID: Int64, readOnlyOrderCount: Networking.OrderCount, in storage: StorageType) {
        storage.deleteAllObjects(ofType: Storage.OrderCountItem.self)
        storage.deleteAllObjects(ofType: Storage.OrderCount.self)

        let newOrderCount = storage.insertNewObject(ofType: Storage.OrderCount.self)
        newOrderCount.update(with: readOnlyOrderCount)

        for item in readOnlyOrderCount.items {
            let newOrderCountItem = storage.insertNewObject(ofType: Storage.OrderCountItem.self)
            newOrderCountItem.update(with: item)
            newOrderCount.addToItems(newOrderCountItem)
        }
    }
}
