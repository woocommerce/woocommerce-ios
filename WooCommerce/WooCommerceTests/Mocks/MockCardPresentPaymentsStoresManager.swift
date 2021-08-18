import Yosemite
@testable import WooCommerce

/// Allows mocking for `CardPresentPaymentAction`.
///
final class MockCardPresentPaymentsStoresManager: DefaultStoresManager {
    private var connectedReaders: [CardReader]
    private var discoveredReader: CardReader?
    private var failDiscovery: Bool

    init(connectedReaders: [CardReader], discoveredReader: CardReader? = nil, sessionManager: SessionManager, failDiscovery: Bool = false) {
        self.connectedReaders = connectedReaders
        self.discoveredReader = discoveredReader
        self.failDiscovery = failDiscovery
        super.init(sessionManager: sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? CardPresentPaymentAction {
            onCardPresentPaymentAction(action: action)
        } else {
            super.dispatch(action)
        }
    }

    private func onCardPresentPaymentAction(action: CardPresentPaymentAction) {
        switch action {
        case .observeConnectedReaders(let onCompletion):
            onCompletion(connectedReaders)
        case .startCardReaderDiscovery(_, let onReaderDiscovered, let onError):
            guard !failDiscovery else {
                onError(MockErrors.discoveryFailure)
                return
            }
            guard let discoveredReader = discoveredReader else {
                return
            }
            onReaderDiscovered([discoveredReader])
        case .connect(let reader, let onCompletion):
            onCompletion(Result.success(reader))
        case .cancelCardReaderDiscovery(let onCompletion):
            onCompletion(Result.success(()))
        default:
            fatalError("Not available")
        }
    }
}

extension MockCardPresentPaymentsStoresManager {
    enum MockErrors: Error {
        case discoveryFailure
    }
}
