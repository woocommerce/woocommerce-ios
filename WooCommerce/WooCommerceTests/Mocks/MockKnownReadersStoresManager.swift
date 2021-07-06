import Yosemite
@testable import WooCommerce

/// Allows mocking for `CardPresentPaymentAction` and  `AppSettingsStoresActions` related to known card readers.
///
final class MockKnownReadersStoresManager: DefaultStoresManager {
    private var knownReaderIDs: [String]
    private var connectedReaders: [CardReader]

    init(knownReaderIDs: [String], connectedReaders: [CardReader], sessionManager: SessionManager) {
        self.knownReaderIDs = knownReaderIDs
        self.connectedReaders = connectedReaders
        super.init(sessionManager: sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? CardPresentPaymentAction {
            onCardPresentPaymentAction(action: action)
        } else if let action = action as? AppSettingsAction {
            onAppSettingsAction(action: action)
        } else {
            super.dispatch(action)
        }
    }

    private func onCardPresentPaymentAction(action: CardPresentPaymentAction) {
        switch action {
        case .connect(let reader, let onCompletion):
            connectedReaders = [reader]
            onCompletion(Result.success(reader))
        case .observeConnectedReaders(let onCompletion):
            onCompletion(connectedReaders)
        default:
            fatalError("Not available")
        }
    }

    private func onAppSettingsAction(action: AppSettingsAction) {
        switch action {
        case .rememberCardReader(let cardReaderID, let onCompletion):
            knownReaderIDs.append(cardReaderID)
            onCompletion(Result.success(()))
        case .forgetCardReader(let cardReaderID, let onCompletion):
            knownReaderIDs = knownReaderIDs.filter { $0 != cardReaderID }
            onCompletion(Result.success(()))
        case .loadCardReaders(let onCompletion):
            onCompletion(Result.success(knownReaderIDs))
        default:
            fatalError("Not available")
        }
    }
}
