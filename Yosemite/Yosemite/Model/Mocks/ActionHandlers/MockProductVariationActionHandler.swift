import Foundation
import Storage

struct MockProductVariationActionHandler: MockActionHandler {

    typealias ActionType = ProductVariationAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {

            /// Not yet implemented
            case .requestMissingVariations(_, let onCompletion):
                success(onCompletion)

            default: unimplementedAction(action: action)
        }
    }
}
