import Foundation
import Storage

struct MockRefundActionHandler: MockActionHandler {

    typealias ActionType = RefundAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {

            /// Not implemented yet
            case .retrieveRefunds(_, _, _, _, let onCompletion):
                success(onCompletion)

            default: unimplementedAction(action: action)
        }
    }
}
