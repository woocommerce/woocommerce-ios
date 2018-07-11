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
extension OrderStore {

    /// Updates (OR Inserts) the specified ReadOnly Order Entity into the Storage Layer.
    ///
    func upsertStoredOrder(readOnlyOrder: Networking.Order) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageOrder = storage.loadOrder(orderID: readOnlyOrder.orderID) ?? storage.insertNewObject(ofType: Storage.Order.self)

        storageOrder.update(with: readOnlyOrder)
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
        }

        storage.saveIfNeeded()
    }
}
