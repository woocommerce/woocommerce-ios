import Foundation
import Storage

struct MockOrderActionHandler: MockActionHandler {

    typealias ActionType = OrderAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .fetchFilteredOrders(let siteID, _, _, _, _, _, _, let writeStrategy, _, let onCompletion):
                fetchFilteredAndAllOrders(siteID: siteID,
                                          writeStrategy: writeStrategy,
                                          onCompletion: onCompletion)
            case .retrieveOrder(let siteID, let orderID, let onCompletion):
                onCompletion(objectGraph.order(forSiteId: siteID, orderId: orderID), nil)
            default: unimplementedAction(action: action)
        }
    }

    func fetchFilteredAndAllOrders(siteID: Int64,
                                   writeStrategy: OrderAction.OrdersStorageWriteStrategy,
                                   onCompletion: @escaping (TimeInterval, Result<[Order], Error>) -> ()) {
        guard writeStrategy != .doNotSave else {
            onCompletion(0, .success([]))
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
