import Foundation
import Storage

struct MockGoogleAdsActionHandler: MockActionHandler {

    typealias ActionType = GoogleAdsAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .checkConnection(_, let onCompletion):
            onCompletion(.success(objectGraph.googleAdsConnection))
        default:
            unimplementedAction(action: action)
        }
    }
}
