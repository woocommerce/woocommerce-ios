import Foundation
import Testing
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
struct PointOfSalePaymentStateAutoLockTests {
    @Test func test_isAutoLockSuppressing_when_all_substates_idle_then_false() {
        // Given
        let state = PointOfSalePaymentState.idle

        // When / Then
        #expect(state.isAutoLockSuppressing == false)
    }

    @Test(arguments: PointOfSaleCardPaymentState.suppressingCases)
    func test_isAutoLockSuppressing_when_card_in_flight_then_true(card: PointOfSaleCardPaymentState) {
        // Given
        let state = PointOfSalePaymentState(card: card, cash: .idle)

        // When / Then
        #expect(state.isAutoLockSuppressing == true)
    }

    @Test(arguments: PointOfSaleCardPaymentState.nonSuppressingCases)
    func test_isAutoLockSuppressing_when_card_idle_or_errored_then_false(card: PointOfSaleCardPaymentState) {
        // Given
        let state = PointOfSalePaymentState(card: card, cash: .idle)

        // When / Then
        #expect(state.isAutoLockSuppressing == false)
    }

    @Test func test_isAutoLockSuppressing_when_cash_collecting_then_true() {
        // Given
        let state = PointOfSalePaymentState(card: .idle, cash: .collectingCash)

        // When / Then
        #expect(state.isAutoLockSuppressing == true)
    }

    @Test func test_isAutoLockSuppressing_when_cash_succeeded_then_true() {
        // Given
        let state = PointOfSalePaymentState(card: .idle, cash: .paymentSuccess)

        // When / Then
        #expect(state.isAutoLockSuppressing == true)
    }

    @Test func test_isAutoLockSuppressing_when_scanToPay_showing_qr_then_true() {
        // Given
        let state = PointOfSalePaymentState(
            card: .idle,
            cash: .idle,
            scanToPay: .showingQRCode(verification: .waiting)
        )

        // When / Then
        #expect(state.isAutoLockSuppressing == true)
    }

    @Test func test_isAutoLockSuppressing_when_scanToPay_succeeded_then_true() {
        // Given
        let state = PointOfSalePaymentState(card: .idle, cash: .idle, scanToPay: .paymentSuccess)

        // When / Then
        #expect(state.isAutoLockSuppressing == true)
    }

    @Test func test_isAutoLockSuppressing_when_markAsPaid_confirming_then_false() {
        // Given
        let state = PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .confirming)

        // When / Then
        #expect(state.isAutoLockSuppressing == false)
    }

    @Test func test_isAutoLockSuppressing_when_markAsPaid_processing_then_true() {
        // Given
        let state = PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .processing)

        // When / Then
        #expect(state.isAutoLockSuppressing == true)
    }

    @Test func test_isAutoLockSuppressing_when_markAsPaid_succeeded_then_true() {
        // Given
        let state = PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .paymentSuccess)

        // When / Then
        #expect(state.isAutoLockSuppressing == true)
    }
}

private extension PointOfSaleCardPaymentState {
    static var suppressingCases: [PointOfSaleCardPaymentState] {
        [.validatingOrder, .preparingReader, .acceptingCard, .cardInserted, .processingPayment, .cardPaymentSuccessful]
    }

    static var nonSuppressingCases: [PointOfSaleCardPaymentState] {
        [.idle, .validatingOrderError, .paymentIntentCreationError, .paymentError]
    }
}
