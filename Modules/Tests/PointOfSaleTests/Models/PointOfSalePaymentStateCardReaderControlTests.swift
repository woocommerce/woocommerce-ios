import Testing
@testable import PointOfSale

struct PointOfSalePaymentStateCardReaderControlTests {
    @Test(arguments: PointOfSalePaymentState.cardReaderControlDisablingCases)
    func test_disablesCardReaderConnectionControl_when_state_should_block_reader_changes_then_true(state: PointOfSalePaymentState) {
        // Given

        // When / Then
        #expect(state.disablesCardReaderConnectionControl == true)
    }

    @Test(arguments: PointOfSalePaymentState.cardReaderControlEnabledCases)
    func test_disablesCardReaderConnectionControl_when_state_allows_reader_changes_then_false(state: PointOfSalePaymentState) {
        // Given

        // When / Then
        #expect(state.disablesCardReaderConnectionControl == false)
    }

    @Test(arguments: PointOfSalePaymentState.automaticCardStartAllowedCases)
    func test_allowsAutomaticCardPaymentStartOnReaderChange_when_checkout_can_restart_card_flow_then_true(state: PointOfSalePaymentState) {
        // Given

        // When / Then
        #expect(state.allowsAutomaticCardPaymentStartOnReaderChange == true)
    }

    @Test(arguments: PointOfSalePaymentState.automaticCardStartBlockedCases)
    func test_allowsAutomaticCardPaymentStartOnReaderChange_when_payment_flow_should_stay_put_then_false(state: PointOfSalePaymentState) {
        // Given

        // When / Then
        #expect(state.allowsAutomaticCardPaymentStartOnReaderChange == false)
    }
}

private extension PointOfSalePaymentState {
    static var cardReaderControlDisablingCases: [PointOfSalePaymentState] {
        [
            PointOfSalePaymentState(card: .processingPayment, cash: .idle)
        ]
    }

    static var cardReaderControlEnabledCases: [PointOfSalePaymentState] {
        let cardStates: [PointOfSaleCardPaymentState] = [
            .idle,
            .validatingOrder,
            .validatingOrderError,
            .paymentIntentCreationError,
            .preparingReader,
            .acceptingCard,
            .cardInserted,
            .paymentError,
            .cardPaymentSuccessful
        ]
        return cardStates.map {
            PointOfSalePaymentState(card: $0, cash: .idle)
        } + [
            PointOfSalePaymentState(card: .idle, cash: .collectingCash),
            PointOfSalePaymentState(card: .idle, cash: .paymentSuccess),
            PointOfSalePaymentState(card: .idle, cash: .idle, scanToPay: .paymentSuccess),
            PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .paymentSuccess)
        ]
    }

    static var automaticCardStartAllowedCases: [PointOfSalePaymentState] {
        let cardStates: [PointOfSaleCardPaymentState] = [
            .idle,
            .validatingOrderError,
            .paymentIntentCreationError,
            .paymentError
        ]
        return cardStates.map {
            PointOfSalePaymentState(card: $0, cash: .idle)
        }
    }

    static var automaticCardStartBlockedCases: [PointOfSalePaymentState] {
        let cardStates: [PointOfSaleCardPaymentState] = [
            .validatingOrder,
            .preparingReader,
            .acceptingCard,
            .cardInserted,
            .processingPayment,
            .cardPaymentSuccessful
        ]
        return cardStates.map {
            PointOfSalePaymentState(card: $0, cash: .idle)
        } + [
            PointOfSalePaymentState(card: .idle, cash: .collectingCash),
            PointOfSalePaymentState(card: .idle, cash: .paymentSuccess),
            PointOfSalePaymentState(card: .idle, cash: .idle, scanToPay: .showingQRCode(verification: .waiting)),
            PointOfSalePaymentState(card: .idle, cash: .idle, scanToPay: .paymentSuccess),
            PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .confirming),
            PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .processing),
            PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .paymentSuccess)
        ]
    }
}
