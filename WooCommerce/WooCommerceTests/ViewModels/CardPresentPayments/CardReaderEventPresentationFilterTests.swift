import Testing
import Yosemite
@testable import WooCommerce

struct CardReaderEventPresentationFilterTests {
    @Test func test_filter_when_reader_rearms_after_multiple_cards_then_keeps_multiple_cards_message_visible() {
        // Given
        let sut = CardReaderEventPresentationFilter()
        let message = CardReaderEvent.displayMessage(.multipleContactlessCardsDetected("Multiple cards"))

        // When
        let displayedMessage = sut.filter(message)
        let waitingForInput = sut.filter(.waitingForInput(.tap))

        // Then
        #expect(displayedMessage == message)
        #expect(waitingForInput == nil)
    }

    @Test func test_filter_when_payment_advances_after_multiple_cards_then_forwards_new_events() {
        // Given
        let sut = CardReaderEventPresentationFilter()
        _ = sut.filter(.displayMessage(.multipleContactlessCardsDetected("Multiple cards")))

        // When
        let cardDetailsCollected = sut.filter(.cardDetailsCollected)
        let waitingForInput = sut.filter(.waitingForInput(.tap))

        // Then
        #expect(cardDetailsCollected == .cardDetailsCollected)
        #expect(waitingForInput == .waitingForInput(.tap))
    }

    @Test func test_filter_when_generic_message_is_received_then_does_not_suppress_waiting_for_input() {
        // Given
        let sut = CardReaderEventPresentationFilter()

        // When
        let displayedMessage = sut.filter(.displayMessage(.generic("Retry card")))
        let waitingForInput = sut.filter(.waitingForInput(.tap))

        // Then
        #expect(displayedMessage == .displayMessage(.generic("Retry card")))
        #expect(waitingForInput == .waitingForInput(.tap))
    }

    @Test func test_reset_when_multiple_cards_message_is_visible_then_forwards_waiting_for_input() {
        // Given
        let sut = CardReaderEventPresentationFilter()
        _ = sut.filter(.displayMessage(.multipleContactlessCardsDetected("Multiple cards")))

        // When
        sut.reset()
        let waitingForInput = sut.filter(.waitingForInput(.tap))

        // Then
        #expect(waitingForInput == .waitingForInput(.tap))
    }
}
