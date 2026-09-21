import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct CardPresentRefundOrchestratorTests {
    @Test func test_refund_when_reader_rearms_after_multiple_cards_then_keeps_message_visible_until_refund_advances() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let sut = CardPresentRefundOrchestrator(stores: stores)
        var onCardReaderMessage: ((CardReaderEvent) -> Void)?
        var displayedMessages: [String] = []
        var waitingForInputCount = 0
        var processingMessageCount = 0
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case let .refundPayment(_, readerMessage, _) = action else { return }
            onCardReaderMessage = readerMessage
        }
        sut.refund(
            amount: 1,
            charge: .fake(),
            paymentGatewayAccount: .fake(),
            onWaitingForInput: { _ in waitingForInputCount += 1 },
            onCardInserted: {},
            onProcessingMessage: { processingMessageCount += 1 },
            onDisplayMessage: { displayedMessages.append($0) },
            onCompletion: { _ in }
        )

        // When
        onCardReaderMessage?(.displayMessage(.multipleContactlessCardsDetected("Try one card")))
        onCardReaderMessage?(.waitingForInput(.tap))
        onCardReaderMessage?(.cardDetailsCollected)

        // Then
        #expect(displayedMessages == ["Try one card"])
        #expect(waitingForInputCount == 0)
        #expect(processingMessageCount == 1)
    }
}
