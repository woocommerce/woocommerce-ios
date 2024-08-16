import XCTest
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentEventPresentationStyleTests: XCTestCase {

    func test_presentationStyle_for_paymentError_tryAnotherPaymentMethod_is_message_paymentError_with_correctActions() {
        // Given
        var spyRetryCalled = false
        let eventDetails = CardPresentPaymentEventDetails.paymentError(
            error: NSError(domain: "test", code: 1),
            retryApproach: .tryAnotherPaymentMethod(retryAction: { spyRetryCalled = true }),
            cancelPayment: {})
        let dependencies = createPresentationStyleDependencies()

        // When
        let presentationStyle =  PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: dependencies)

        // Then
        guard case .message(.paymentError(let viewModel)) = presentationStyle else {
            return XCTFail("Expected payment error message not found")
        }

        viewModel.tryAgainButtonViewModel.actionHandler()
        XCTAssertTrue(spyRetryCalled)

        XCTAssertNil(viewModel.backToCheckoutButtonViewModel)
    }

    func test_presentationStyle_for_paymentError_tryPaymentAgain_is_message_paymentError_with_correctActions() {
        // Given
        var spyRetryCalled = false
        let eventDetails = CardPresentPaymentEventDetails.paymentError(
            error: NSError(domain: "test", code: 1),
            retryApproach: .tryAgain(retryAction: { spyRetryCalled = true }),
            cancelPayment: {})
        var spyBackToCheckoutCalled = false
        let dependencies = createPresentationStyleDependencies(tryPaymentAgainBackToCheckoutAction: { spyBackToCheckoutCalled = true })

        // When
        let presentationStyle =  PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: dependencies)

        // Then
        guard case .message(.paymentError(let viewModel)) = presentationStyle else {
            return XCTFail("Expected payment error message not found")
        }

        viewModel.tryAgainButtonViewModel.actionHandler()
        XCTAssertTrue(spyRetryCalled)

        viewModel.backToCheckoutButtonViewModel?.actionHandler()
        XCTAssertTrue(spyBackToCheckoutCalled)
    }

    func test_presentationStyle_for_paymentError_dontRetry_is_message_paymentErrorNonRetryable_with_correctActions() {
        // Given
        let eventDetails = CardPresentPaymentEventDetails.paymentError(
            error: NSError(domain: "test", code: 1),
            retryApproach: .dontRetry,
            cancelPayment: {})
        var spyTryAnotherPaymentMethod = false
        let dependencies = createPresentationStyleDependencies(nonRetryableErrorExitAction: { spyTryAnotherPaymentMethod = true })

        // When
        let presentationStyle =  PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: dependencies)

        // Then
        guard case .message(.paymentErrorNonRetryable(let viewModel)) = presentationStyle else {
            return XCTFail("Expected payment error message not found")
        }

        viewModel.tryAnotherPaymentMethodButtonViewModel.actionHandler()
        XCTAssertTrue(spyTryAnotherPaymentMethod)
    }

    func test_presentationStyle_for_paymentSuccess_is_message_paymentSuccess_with_order_total() {
        // Given
        let eventDetails = CardPresentPaymentEventDetails.paymentSuccess(done: {})
        let dependencies = createPresentationStyleDependencies(formattedOrderTotalPrice: "$200.50")

        // When
        let presentationStyle = PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: dependencies)

        // Then
        guard case .message(.paymentSuccess(let viewModel)) = presentationStyle else {
            return XCTFail("Expected payment success message not found")
        }

        XCTAssertEqual(viewModel.message, "A payment of $200.50 was successfully made")
    }

    func test_presentationStyle_for_paymentCaptureError_is_message_paymentCaptureError_with_correctActions() {
        // Given
        let eventDetails = CardPresentPaymentEventDetails.paymentCaptureError(cancelPayment: {})
        var spyPaymentCaptureErrorTryAgainCalled = false
        var spyPaymentCaptureErrorNewOrderCalled = false
        let dependencies = createPresentationStyleDependencies(
            paymentCaptureErrorTryAgainAction: {
                spyPaymentCaptureErrorTryAgainCalled = true
            },
            paymentCaptureErrorNewOrderAction: {
                spyPaymentCaptureErrorNewOrderCalled = true
            }
        )

        // When
        let presentationStyle = PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: dependencies)

        // Then
        guard case .message(.paymentCaptureError(let viewModel)) = presentationStyle else {
            return XCTFail("Expected payment capture error message not found")
        }

        viewModel.tryAgainButtonViewModel.actionHandler()
        viewModel.newOrderButtonViewModel.actionHandler()
        XCTAssertTrue(spyPaymentCaptureErrorTryAgainCalled)
        XCTAssertTrue(spyPaymentCaptureErrorNewOrderCalled)
    }

    func createPresentationStyleDependencies(
        tryPaymentAgainBackToCheckoutAction: @escaping () -> Void = {},
        nonRetryableErrorExitAction: @escaping () -> Void = {},
        formattedOrderTotalPrice: String? = nil,
        paymentCaptureErrorTryAgainAction: @escaping () -> Void = {},
        paymentCaptureErrorNewOrderAction: @escaping () -> Void = {}) -> PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies {
            PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies(
                tryPaymentAgainBackToCheckoutAction: tryPaymentAgainBackToCheckoutAction,
                nonRetryableErrorExitAction: nonRetryableErrorExitAction,
                formattedOrderTotalPrice: formattedOrderTotalPrice,
                paymentCaptureErrorTryAgainAction: paymentCaptureErrorTryAgainAction,
                paymentCaptureErrorNewOrderAction: paymentCaptureErrorNewOrderAction
            )
        }

}
