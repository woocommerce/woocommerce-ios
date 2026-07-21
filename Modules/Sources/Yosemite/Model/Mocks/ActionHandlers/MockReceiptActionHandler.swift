import Foundation
import Storage

struct MockReceiptActionHandler: MockActionHandler {
    typealias ActionType = ReceiptAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        unimplementedAction(action: action)
    }
}
