import Foundation
import Storage

struct MockOrderNoteActionHandler: MockActionHandler {

    typealias ActionType = OrderNoteAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .retrieveOrderNotes(let siteID, let orderID, let onCompletion):
                retrieveOrderNotes(siteId: siteID, orderId: orderID, onCompletion: onCompletion)

            default: unimplementedAction(action: action)
        }
    }

    func retrieveOrderNotes(siteId: Int64, orderId: Int64, onCompletion: ([OrderNote]?, Error?) -> Void) {
        onCompletion([], nil) // TODO – set this
    }
}
