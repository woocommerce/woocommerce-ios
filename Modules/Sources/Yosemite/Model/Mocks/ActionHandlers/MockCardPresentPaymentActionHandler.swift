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
        case .checkDeviceSupport(_, _, _, _, let onCompletion):
            onCompletion(true)
        case .observeConnectedReaders(let onCompletion):
            observeConnectedReaders(onCompletion: onCompletion)
        case .observeCardReaderUpdateState(let onCompletion):
            observeCardReaderUpdateState(onCompletion: onCompletion)
        case .collectPayment(_, _, _, let onCardReaderMessage, _, _):
            // This immediately brings up the `CardPresentModalTapCard` screen, which is used by
            // `WooCommerceScreenshots` to display it for screenshotting purpose.
            onCardReaderMessage(.waitingForInput([.tap, .swipe, .insert]))
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

    private func observeConnectedReaders(onCompletion: @escaping ([CardReader]) -> Void) {
        let cardReaders = objectGraph.cardReaders
        onCompletion(cardReaders)
    }

    private func observeCardReaderUpdateState(onCompletion: @escaping (AnyPublisher<Yosemite.CardReaderSoftwareUpdateState, Never>) -> Void) {
        onCompletion(Just(.none).eraseToAnyPublisher())
    }
}
