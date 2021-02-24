import Foundation
import Storage

struct MockShipmentActionHandler: MockActionHandler {
    typealias ActionType = ShipmentAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .synchronizeShipmentTrackingData(_, _, let onCompletion):
                success(onCompletion)

            default: unimplementedAction(action: action)
        }
    }
}
