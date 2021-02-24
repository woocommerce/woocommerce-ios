import Foundation
import Storage

struct MockOrderStatusActionHandler: MockActionHandler {

    typealias ActionType = OrderStatusAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            // Order status is not currently supported by `MockObjectGraph`, so pretend none exist
            case .retrieveOrderStatuses(_, let onCompletion): success(onCompletion)
            default: unimplementedAction(action: action)
        }
    }
}
