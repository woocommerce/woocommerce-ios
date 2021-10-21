import Foundation
import Storage

struct MockOrderActionHandler: MockActionHandler {

    typealias ActionType = OrderAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .fetchFilteredAndAllOrders(let siteID, _, _, _, _, _, let onCompletion):
                fetchFilteredAndAllOrders(siteID: siteID, onCompletion: onCompletion)
            case .retrieveOrder(let siteID, let orderID, let onCompletion):
                onCompletion(objectGraph.order(forSiteId: siteID, orderId: orderID), nil)
            default: unimplementedAction(action: action)
        }
    }

    func fetchFilteredAndAllOrders(siteID: Int64, onCompletion: @escaping (TimeInterval, Error?) -> ()) {
        saveOrders(orders: objectGraph.orders(forSiteId: siteID)) {
            onCompletion(0, nil)
        }
    }

    private func saveOrders(orders: [Order], onCompletion: @escaping () -> ()) {
        let storage = storageManager.writerDerivedStorage

        storage.perform {
            let updater = OrdersUpsertUseCase(storage: storage)
            updater.upsert(orders)
        }

        storageManager.saveDerivedType(derivedStorage: storage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}
