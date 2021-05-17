import Combine
import Yosemite
@testable import WooCommerce

/// Allows mocking for `CardPresentPaymentAction`.
///
final class MockCardPresentPaymentsStoresManager: DefaultStoresManager {
    private var knownReaders: [CardReader]

    init(knownReaders: [CardReader], sessionManager: SessionManager) {
        self.knownReaders = knownReaders
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
        case .observeKnownReaders(let onCompletion):
            onCompletion(knownReaders)
        default:
            fatalError("Not available")
        }
    }
}
