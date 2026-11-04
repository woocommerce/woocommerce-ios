import Foundation
import Storage

struct MockWooShippingActionHandler: MockActionHandler {
    typealias ActionType = WooShippingAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .loadServiceStatusNotices(_, let onCompletion):
            onCompletion(.success([]))
        default:
            unimplementedAction(action: action)
        }
    }
}
