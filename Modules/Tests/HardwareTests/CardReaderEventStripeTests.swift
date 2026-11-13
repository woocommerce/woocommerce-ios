#if !targetEnvironment(macCatalyst)
import StripeTerminal
import Testing
@testable import Hardware

struct CardReaderEventStripeTests {
    @Test func test_make_when_multiple_contactless_cards_are_detected_then_returns_typed_display_message() {
        // Given
        let stripeMessage = ReaderDisplayMessage.multipleContactlessCardsDetected

        // When
        let event = CardReaderEvent.make(displayMessage: stripeMessage)

        // Then
        #expect(event == .displayMessage(.multipleContactlessCardsDetected(
            "Multiple cards detected. Try again with a single card."
        )))
    }

    @Test func test_make_when_generic_reader_message_is_received_then_returns_generic_display_message() {
        // Given
        let stripeMessage = ReaderDisplayMessage.retryCard

        // When
        let event = CardReaderEvent.make(displayMessage: stripeMessage)

        // Then
        #expect(event == .displayMessage(.generic("Retry Card")))
    }

    @Test func test_make_when_remove_card_is_received_then_returns_remove_card_request() {
        // Given
        let stripeMessage = ReaderDisplayMessage.removeCard

        // When
        let event = CardReaderEvent.make(displayMessage: stripeMessage)

        // Then
        #expect(event == .removeCardRequested("Remove Card"))
    }
}
#endif
