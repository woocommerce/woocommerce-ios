import Foundation
import Storage
import Networking

struct MockCardPresentPaymentActionHandler: MockActionHandler {
    typealias ActionType = CardPresentPaymentAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .loadAccounts(let siteID, let onCompletion):
            loadAccounts(siteID: siteID, onCompletion: onCompletion)
        default:
            break
        }
    }

    private func loadAccounts(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let accounts = objectGraph.paymentGatewayAccounts(for: siteID)

        save(mocks: accounts, as: StoragePaymentGatewayAccount.self) { error in
            if let error = error {
                onCompletion(.failure(error))
            } else {
                onCompletion(.success(()))
            }
        }
    }
}
