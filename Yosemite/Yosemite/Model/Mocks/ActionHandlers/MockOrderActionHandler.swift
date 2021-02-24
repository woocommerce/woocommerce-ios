import Foundation
import Storage

struct MockOrderActionHandler: MockActionHandler {

    typealias ActionType = OrderAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .fetchFilteredAndAllOrders(let siteID, _, _, _, _, let onCompletion):
                fetchFilteredAndAllOrders(siteID: siteID, onCompletion: onCompletion)
            case .countProcessingOrders(let siteID, let onCompletion):
                countOrders(status: .processing, siteID: siteID, onCompletion: onCompletion)

            default: unimplementedAction(action: action)
        }
    }

    func fetchFilteredAndAllOrders(siteID: Int64, onCompletion: @escaping (TimeInterval, Error?) -> ()) {
        saveOrders(orders: objectGraph.orders(forSiteId: siteID)) {
            onCompletion(0, nil)
        }
    }

    func countOrders(status: OrderStatusEnum, siteID: Int64, onCompletion: (OrderCount?, Error?) -> Void) {
        let count = objectGraph.orders(withStatus: status, forSiteId: siteID).count

        onCompletion(OrderCount(siteID: siteID, items: [
            OrderCountItem(slug: "", name: "", total: count)
        ]), nil)
    }

    private func saveOrders(orders: [Order], onCompletion: @escaping () -> ()) {
        let storage = storageManager.newDerivedStorage()

        storage.perform {
            let updater = OrdersUpsertUseCase(storage: storage)
            updater.upsert(orders)
        }

        storageManager.saveDerivedType(derivedStorage: storage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}
