import Foundation
import Storage

struct MockReceiptActionHandler: MockActionHandler {
    typealias ActionType = ReceiptAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .loadReceipt(_, let onCompletion):
            onCompletion(.failure(ReceiptStoreError.fileNotFound))
        default: unimplementedAction(action: action)
        }
    }
}
