import Yosemite
@testable import WooCommerce

/// Allows mocking for `CardPresentPaymentAction`.
///
final class MockCardPresentPaymentsStoresManager: DefaultStoresManager {
    private var connectedReaders: [CardReader]
    private var discoveredReader: CardReader?
    private var failDiscovery: Bool
    private var readerUpdateAvailable: Bool
    private var failReaderUpdateCheck: Bool
    private var failUpdate: Bool
    private var failConnection: Bool

    init(connectedReaders: [CardReader],
         discoveredReader: CardReader? = nil,
         sessionManager: SessionManager,
         failDiscovery: Bool = false,
         readerUpdateAvailable: Bool = false,
         failReaderUpdateCheck: Bool = false,
         failUpdate: Bool = false,
         failConnection: Bool = false
    ) {
        self.connectedReaders = connectedReaders
        self.discoveredReader = discoveredReader
        self.failDiscovery = failDiscovery
        self.readerUpdateAvailable = readerUpdateAvailable
        self.failReaderUpdateCheck = failReaderUpdateCheck
        self.failUpdate = failUpdate
        self.failConnection = failConnection
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
            guard !failConnection else {
                onCompletion(Result.failure(MockErrors.connectionFailure))
                return
            }
            onCompletion(Result.success(reader))
        case .cancelCardReaderDiscovery(let onCompletion):
            onCompletion(Result.success(()))
        case .checkForCardReaderUpdate(let onCompletion):
            guard !failReaderUpdateCheck else {
                onCompletion(Result.failure(MockErrors.readerUpdateCheckFailure))
                return
            }
            guard readerUpdateAvailable else {
                onCompletion(Result.success(nil))
                return
            }
            onCompletion(Result.success(mockUpdate()))
        case .startCardReaderUpdate(let onProgress, let onCompletion):
            onProgress(0.5)
            guard !failUpdate else {
                onCompletion(Result.failure(MockErrors.readerUpdateFailure))
                return
            }
            onCompletion(Result.success(()))
        default:
            fatalError("Not available")
        }
    }
}

extension MockCardPresentPaymentsStoresManager {
    enum MockErrors: Error {
        case discoveryFailure
        case readerUpdateCheckFailure
        case readerUpdateFailure
        case connectionFailure
    }
}

extension MockCardPresentPaymentsStoresManager {
    func mockUpdate() -> CardReaderSoftwareUpdate {
        CardReaderSoftwareUpdate(
            estimatedUpdateTime: .betweenFiveAndFifteenMinutes,
            deviceSoftwareVersion: "MOCKVERSION"
        )
    }
}
