import Testing
@testable import PointOfSale

struct PointOfSalePaymentStateAutoLockTests {
    @Test(arguments: PointOfSalePaymentState.suppressingCases)
    func test_isAutoLockSuppressing_when_state_suppresses_auto_lock_then_true(state: PointOfSalePaymentState) {
        // Given

        // When / Then
        #expect(state.isAutoLockSuppressing == true)
    }

    @Test(arguments: PointOfSalePaymentState.nonSuppressingCases)
    func test_isAutoLockSuppressing_when_state_does_not_suppress_auto_lock_then_false(state: PointOfSalePaymentState) {
        // Given

        // When / Then
        #expect(state.isAutoLockSuppressing == false)
    }
}

private extension PointOfSalePaymentState {
    static var suppressingCases: [PointOfSalePaymentState] {
        let suppressingCardStates: [PointOfSaleCardPaymentState] = [
            .validatingOrder, .preparingReader, .acceptingCard, .cardInserted, .processingPayment
        ]
        return suppressingCardStates.map {
            PointOfSalePaymentState(card: $0, cash: .idle)
        } + [
            PointOfSalePaymentState(card: .idle, cash: .idle, scanToPay: .showingQRCode(verification: .waiting)),
            PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .processing)
        ]
    }

    static var nonSuppressingCases: [PointOfSalePaymentState] {
        let nonSuppressingCardStates: [PointOfSaleCardPaymentState] = [
            .idle, .validatingOrderError, .paymentIntentCreationError, .paymentError, .cardPaymentSuccessful
        ]
        return nonSuppressingCardStates.map {
            PointOfSalePaymentState(card: $0, cash: .idle)
        } + [
            PointOfSalePaymentState(card: .idle, cash: .collectingCash),
            PointOfSalePaymentState(card: .idle, cash: .paymentSuccess),
            PointOfSalePaymentState(card: .idle, cash: .idle, scanToPay: .paymentSuccess),
            PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .confirming),
            PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .paymentSuccess)
        ]
    }
}
