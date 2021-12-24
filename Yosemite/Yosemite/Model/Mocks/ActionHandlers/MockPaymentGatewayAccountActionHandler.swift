import Foundation
import Storage

struct MockPaymentGatewayAccountActionHandler: MockActionHandler {
    typealias ActionType = PaymentGatewayAccountAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .loadAccounts(_, let onCompletion):
            onCompletion(.success(()))
        default: unimplementedAction(action: action)
        }
    }
}
