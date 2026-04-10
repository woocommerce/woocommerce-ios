import Foundation
import Storage

struct MockOrderNoteActionHandler: MockActionHandler {

    typealias ActionType = OrderNoteAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            // Order notes is not currently supported by `MockObjectGraph`, so pretend none exist
            case .retrieveOrderNotes(_, _, let onCompletion): success(onCompletion)
            default: unimplementedAction(action: action)
        }
    }
}
