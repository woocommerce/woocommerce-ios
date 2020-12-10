import Foundation
import Storage

struct MockOrderStatusActionHandler: MockActionHandler {

    typealias ActionType = OrderStatusAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .retrieveOrderStatuses(let siteID, let onCompletion):
                retrieveOrderStatuses(siteId: siteID, onCompletion: onCompletion)

            default: unimplementedAction(action: action)
        }
    }

    func retrieveOrderStatuses(siteId: Int64, onCompletion: ([OrderStatus]?, Error?) -> Void) {
        onCompletion([], nil) // Todo
    }
}
