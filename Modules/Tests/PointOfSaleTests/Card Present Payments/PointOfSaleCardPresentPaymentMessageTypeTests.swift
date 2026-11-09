import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct PointOfSaleCardPresentPaymentMessageTypeTests {
    @Test
    func test_isStatusScreen_when_payment_is_cancelled_on_reader_then_returns_true() {
        // Given
        let messageType = PointOfSaleCardPresentPaymentMessageType.cancelledOnReader(
            viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel(tryPaymentAgainButtonAction: {}))

        // When
        let isStatusScreen = messageType.isStatusScreen

        // Then
        #expect(isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_payment_succeeded_then_returns_true() {
        // Given
        let messageType = PointOfSaleCardPresentPaymentMessageType.paymentSuccess(
            viewModel: PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$10.00", paymentMethod: .card))

        // When
        let isStatusScreen = messageType.isStatusScreen

        // Then
        #expect(isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_payment_is_processing_then_returns_false() {
        // Given
        let messageType = PointOfSaleCardPresentPaymentMessageType.processing(
            viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel())

        // When
        let isStatusScreen = messageType.isStatusScreen

        // Then
        #expect(!isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_order_validation_failed_then_returns_false() {
        // Given
        let messageType = PointOfSaleCardPresentPaymentMessageType.validatingOrderError(
            viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel(error: NSError(domain: "test", code: 1),
                                                                                         retryApproach: .dontRetry))

        // When
        let isStatusScreen = messageType.isStatusScreen

        // Then
        #expect(!isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_payment_intent_creation_failed_then_returns_false() {
        // Given
        let messageType = PointOfSaleCardPresentPaymentMessageType.paymentIntentCreationError(
            viewModel: PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel(error: NSError(domain: "test", code: 1),
                                                                                         tryPaymentAgainButtonAction: {},
                                                                                         editOrderButtonAction: {}))

        // When
        let isStatusScreen = messageType.isStatusScreen

        // Then
        #expect(!isStatusScreen)
    }
}
