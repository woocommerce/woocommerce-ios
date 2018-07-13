import Foundation
import Networking
import Storage


// MARK: - OrderStore
//
public class OrderStore: Store {

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
        case .retrieveOrders(let siteId, let onCompletion):
            retrieveOrders(siteId: siteId, onCompletion: onCompletion)
        case .retrieveOrder(let siteId, let orderId, let onCompletion):
            retrieveOrder(siteId: siteId, orderId: orderId, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension OrderStore  {

    /// Retrieves the orders associated with a given Site ID (if any!).
    ///
    func retrieveOrders(siteId: Int, onCompletion: @escaping ([Order]?, Error?) -> Void) {
        let remote = OrdersRemote(network: network)

        remote.loadAllOrders(for: siteId) { [weak self] (orders, error) in
            guard let orders = orders else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredOrders(readOnlyOrders: orders)
            onCompletion(orders, nil)
        }
    }

    /// Retrieves a specific order associated with a given Site ID (if any!).
    ///
    func retrieveOrder(siteId: Int, orderId: Int, onCompletion: @escaping (Order?, Error?) -> Void) {
        let remote = OrdersRemote(network: network)

        remote.loadOrder(for: siteId, orderID: orderId) { [weak self] (order, error) in
            guard let order = order else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredOrder(readOnlyOrder: order)
            onCompletion(order, nil)
        }
    }
}


// MARK: - Persistance
//
private extension OrderStore {

    /// Updates (OR Inserts) the specified ReadOnly Order Entity into the Storage Layer.
    ///
    func upsertStoredOrder(readOnlyOrder: Networking.Order) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageOrder = storage.loadOrder(orderID: readOnlyOrder.orderID) ?? storage.insertNewObject(ofType: Storage.Order.self)
        storageOrder.update(with: readOnlyOrder)
        handleOrderItems(readOnlyOrder, storageOrder, storage)
        handleOrderCoupons(readOnlyOrder, storageOrder, storage)
        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified ReadOnly Order Entities into the Storage Layer.
    ///
    func upsertStoredOrders(readOnlyOrders: [Networking.Order]) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        for readOnlyOrder in readOnlyOrders {
            let storageOrder = storage.loadOrder(orderID: readOnlyOrder.orderID) ?? storage.insertNewObject(ofType: Storage.Order.self)
            storageOrder.update(with: readOnlyOrder)
            handleOrderItems(readOnlyOrder, storageOrder, storage)
            handleOrderCoupons(readOnlyOrder, storageOrder, storage)
        }

        storage.saveIfNeeded()
    }

    /// Updates, inserts, or prunes the provided StorageOrder's items using the provided read-only Order's items
    ///
    func handleOrderItems(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        guard !readOnlyOrder.items.isEmpty else {
            // No items in the read-only order, so remove all the items in Storage.Order
            storageOrder.items?.forEach { storageOrder.removeFromItems($0) }
            return
        }

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
        storageOrder.items?.forEach({ storageItem in
            if readOnlyOrder.items.first(where: { $0.itemID == storageItem.itemID } ) == nil {
                storageOrder.removeFromItems(storageItem)
            }
        })
    }

    /// Updates, inserts, or prunes the provided StorageOrder's coupons using the provided read-only Order's coupons
    ///
    func handleOrderCoupons(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        guard !readOnlyOrder.coupons.isEmpty else {
            // No coupons in the read-only order, so remove all the coupons in Storage.Order
            storageOrder.coupons?.forEach { storageOrder.removeFromCoupons($0) }
            return
        }

        // Upsert the coupons from the read-only order
        for readOnlyCoupon in readOnlyOrder.coupons {
            if let existingStorageCoupon = storage.loadCouponItem(couponID: readOnlyCoupon.couponID) {
                existingStorageCoupon.update(with: readOnlyCoupon)
            } else {
                let newStorageCoupon = storage.insertNewObject(ofType: Storage.OrderCoupon.self)
                newStorageCoupon.update(with: readOnlyCoupon)
                storageOrder.addToCoupons(newStorageCoupon)
            }
        }

        // Now, remove any objects that exist in storageOrder.coupons but not in readOnlyOrder.coupons
        storageOrder.coupons?.forEach({ storageCoupon in
            if readOnlyOrder.coupons.first(where: { $0.couponID == storageCoupon.couponID } ) == nil {
                storageOrder.removeFromCoupons(storageCoupon)
            }
        })
    }
}
