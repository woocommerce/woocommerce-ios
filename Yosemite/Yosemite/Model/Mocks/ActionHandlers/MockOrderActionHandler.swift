import Foundation
import Storage

struct MockOrderActionHandler: MockActionHandler {

    typealias ActionType = OrderAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .fetchFilteredOrders(let siteID, _, _, _, _, _, _, let writeStrategy, let pageSize, let onCompletion):
            fetchFilteredAndAllOrders(siteID: siteID,
                                      writeStrategy: writeStrategy,
                                      pageSize: pageSize,
                                      onCompletion: onCompletion)
        case .retrieveOrder(let siteID, let orderID, let onCompletion):
            onCompletion(objectGraph.order(forSiteId: siteID, orderId: orderID), nil)
        case .checkIfStoreHasOrders(_, let onCompletion):
            onCompletion(.success(true))
        case .retrieveOrderRemotely(let siteId, let orderId, let onCompletion):
            if let order = objectGraph.order(forSiteId: siteId, orderId: orderId) {
                onCompletion(.success(order))
            } else {
                onCompletion(.failure(NSError(domain: "", code: 0)))
            }

        default: unimplementedAction(action: action)
        }
    }

    func fetchFilteredAndAllOrders(siteID: Int64,
                                   writeStrategy: OrderAction.OrdersStorageWriteStrategy,
                                   pageSize: Int,
                                   onCompletion: @escaping (TimeInterval, Result<[Order], Error>) -> ()) {
        guard writeStrategy != .doNotSave else {
            let sortedOrders = Array(objectGraph.orders(forSiteId: siteID)
                .sorted(by: { $0.dateCreated > $1.dateCreated })
                .prefix(pageSize))
            onCompletion(0, .success(sortedOrders))
            return
        }

        saveOrders(orders: objectGraph.orders(forSiteId: siteID)) {
            onCompletion(0, .success([]))
        }
    }

    private func saveOrders(orders: [Order], onCompletion: @escaping () -> ()) {
        let storage = storageManager.viewStorage

        storage.perform {
            let updater = OrdersUpsertUseCase(storage: storage)
            updater.upsert(orders)
        }

        storageManager.saveDerivedType(derivedStorage: storage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}
