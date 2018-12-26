import Foundation
import Networking
import Storage


// MARK: - OrderStore
//
public class OrderStore: Store {

    /// Shared private StorageType for use during then entire Orders sync process
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
        case .synchronizeOrders(let siteID, let status, let pageNumber, let pageSize, let onCompletion):
            synchronizeOrders(siteID: siteID, status: status, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .updateOrder(let siteID, let orderID, let status, let onCompletion):
            updateOrder(siteID: siteID, orderID: orderID, status: status, onCompletion: onCompletion)
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

        onCompletion()
    }

    /// Searches all of the orders that contain a given Keyword.
    ///
    func searchOrders(siteID: Int, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
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

    /// Retrieves the orders associated with a given Site ID (if any!).
    ///
    func synchronizeOrders(siteID: Int, status: OrderStatus?, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = OrdersRemote(network: network)

        remote.loadAllOrders(for: siteID, status: status?.rawValue, pageNumber: pageNumber, pageSize: pageSize) { [weak self] (orders, error) in
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
    func retrieveOrder(siteID: Int, orderID: Int, onCompletion: @escaping (Order?, Error?) -> Void) {
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
    func updateOrder(siteID: Int, orderID: Int, status: OrderStatus, onCompletion: @escaping (Error?) -> Void) {
        /// Optimistically update the Status
        let oldStatus = updateOrderStatus(orderID: orderID, status: status)

        let remote = OrdersRemote(network: network)
        remote.updateOrder(from: siteID, orderID: orderID, status: status.rawValue) { [weak self] (order, error) in
            guard let error = error else {
                // NOTE: We're *not* actually updating the whole entity here. Reason: Prevent UI inconsistencies!!
                onCompletion(nil)
                return
            }

            /// Revert Optimistic Update
            self?.updateOrderStatus(orderID: orderID, status: oldStatus)
            onCompletion(error)
        }
    }
}


// MARK: - Storage
//
extension OrderStore {

    /// Deletes any Storage.Order with the specified OrderID
    ///
    func deleteStoredOrder(orderID: Int) {
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
    func updateOrderStatus(orderID: Int, status: OrderStatus) -> OrderStatus {
        let storage = storageManager.viewStorage
        guard let order = storage.loadOrder(orderID: orderID) else {
            return status
        }

        let oldStatus = OrderStatus(rawValue: order.status)
        order.status = status.rawValue
        storage.saveIfNeeded()

        return oldStatus
    }
}


// MARK: - Storage: Search Results
//
extension OrderStore {

    /// Upserts the Orders, and associates them to the Search Results Entity (in Background)
    ///
    private func upsertSearchResultsInBackground(keyword: String, readOnlyOrders: [Networking.Order], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.upsertStoredOrders(readOnlyOrders: readOnlyOrders, in: derivedStorage)
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
            storage.loadOrder(orderID: readOnlyOrder.orderID)?.addToSearchResults(searchResults)
        }
    }
}


// MARK: - Storage: Orders
//
extension OrderStore {

    /// Unit Testing Helper: Updates or Inserts the specified ReadOnly Order in a given Storage Layer.
    ///
    func upsertStoredOrder(readOnlyOrder: Networking.Order, in storage: StorageType) {
        upsertStoredOrders(readOnlyOrders: [readOnlyOrder], in: storage)
    }

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
    private func upsertStoredOrders(readOnlyOrders: [Networking.Order], in storage: StorageType) {
        for readOnlyOrder in readOnlyOrders {
            let storageOrder = storage.loadOrder(orderID: readOnlyOrder.orderID) ?? storage.insertNewObject(ofType: Storage.Order.self)
            storageOrder.update(with: readOnlyOrder)

            handleOrderItems(readOnlyOrder, storageOrder, storage)
            handleOrderCoupons(readOnlyOrder, storageOrder, storage)
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's items using the provided read-only Order's items
    ///
    private func handleOrderItems(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Upsert the items from the read-only order
        for readOnlyItem in readOnlyOrder.items {
            if let existingStorageItem = storage.loadOrderItem(itemID: readOnlyItem.itemID) {
                existingStorageItem.update(with: readOnlyItem)
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.OrderItem.self)
                newStorageItem.update(with: readOnlyItem)
                storageOrder.addToItems(newStorageItem)
            }
        }

        // Now, remove any objects that exist in storageOrder.items but not in readOnlyOrder.items
        storageOrder.items?.forEach { storageItem in
            if readOnlyOrder.items.first(where: { $0.itemID == storageItem.itemID } ) == nil {
                storageOrder.removeFromItems(storageItem)
                storage.deleteObject(storageItem)
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
}
