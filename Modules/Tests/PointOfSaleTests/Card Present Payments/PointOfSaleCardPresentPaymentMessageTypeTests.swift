import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct PointOfSaleCardPresentPaymentMessageTypeTests {
    @Test
    func test_isStatusScreen_when_payment_is_cancelled_on_reader_then_returns_true() {
        let messageType = PointOfSaleCardPresentPaymentMessageType.cancelledOnReader(
            viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel(tryPaymentAgainButtonAction: {}))

        let isStatusScreen = messageType.isStatusScreen

        #expect(isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_payment_succeeded_then_returns_true() {
        let messageType = PointOfSaleCardPresentPaymentMessageType.paymentSuccess(
            viewModel: PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$10.00", paymentMethod: .card))

        let isStatusScreen = messageType.isStatusScreen

        #expect(isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_payment_is_processing_then_returns_false() {
        let messageType = PointOfSaleCardPresentPaymentMessageType.processing(
            viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel())

        let isStatusScreen = messageType.isStatusScreen

        #expect(!isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_order_validation_failed_then_returns_false() {
        let messageType = PointOfSaleCardPresentPaymentMessageType.validatingOrderError(
            viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel(error: NSError(domain: "test", code: 1),
                                                                                         retryApproach: .dontRetry))

        let isStatusScreen = messageType.isStatusScreen

        #expect(!isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_payment_intent_creation_failed_then_returns_false() {
        let messageType = PointOfSaleCardPresentPaymentMessageType.paymentIntentCreationError(
            viewModel: PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel(error: NSError(domain: "test", code: 1),
                                                                                         tryPaymentAgainButtonAction: {},
                                                                                         editOrderButtonAction: {}))

        let isStatusScreen = messageType.isStatusScreen

        #expect(!isStatusScreen)
    }
}
