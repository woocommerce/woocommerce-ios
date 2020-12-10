import Foundation
import Storage

struct MockOrderActionHandler: MockActionHandler {

    typealias ActionType = OrderAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .fetchFilteredAndAllOrders(let siteId, _, _, _, _, let onCompletion):
                saveOrders(siteId: siteId, onCompletion: onCompletion)
            case .countProcessingOrders(let siteID, let onCompletion):
                countOrders(status: .processing, siteId: siteID, onCompletion: onCompletion)

            default: unimplementedAction(action: action)
        }
    }

    private func countOrders(status: OrderStatusEnum, siteId: Int64, onCompletion: (OrderCount?, Error?) -> Void) {
        let count = objectGraph.orders(withStatus: status, forSiteId: siteId).count

        onCompletion(OrderCount(siteID: siteId, items: [
            OrderCountItem(slug: "", name: "", total: count)
        ]), nil)
    }

    private func saveOrders(siteId: Int64, onCompletion: @escaping (Error?) -> ()) {
        let updater = OrdersUpsertUseCase(storage: storageManager.newDerivedStorage())
        updater.upsert(objectGraph.orders(forSiteId: siteId))
        onCompletion(nil)
    }
}
