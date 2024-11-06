import Foundation
import Storage

struct MockJustInTimeMessageActionHandler: MockActionHandler {

    typealias ActionType = JustInTimeMessageAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .loadMessage:
            break
        default:
            unimplementedAction(action: action)
        }
    }
}
