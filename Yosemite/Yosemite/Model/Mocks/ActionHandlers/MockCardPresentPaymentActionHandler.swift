import Foundation
import Storage
import Networking
import Combine

struct MockCardPresentPaymentActionHandler: MockActionHandler {
    typealias ActionType = CardPresentPaymentAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .loadAccounts(let siteID, let onCompletion):
            loadAccounts(siteID: siteID, onCompletion: onCompletion)
        case .publishCardReaderConnections(let onCompletion):
            publishCardReaderConnections(onCompletion: onCompletion)
        case .selectedPaymentGatewayAccount(let onCompletion):
            onCompletion(objectGraph.paymentGatewayAccounts.first)
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

    private func publishCardReaderConnections(onCompletion: @escaping (AnyPublisher<[CardReader], Never>) -> Void) {
        let cardReaders = objectGraph.cardReaders
        onCompletion(Just(cardReaders).eraseToAnyPublisher())
    }
}
