import Foundation
import Storage

struct MockShippingLabelActionHandler: MockActionHandler {
    typealias ActionType = ShippingLabelAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            /// Not implemented
            case .synchronizeShippingLabels(_, _, let completion):
                success(completion)
            case .checkCreationEligibility(_, _, _, _, _, let onCompletion):
                onCompletion(false)
            default: unimplementedAction(action: action)
        }
    }
}
