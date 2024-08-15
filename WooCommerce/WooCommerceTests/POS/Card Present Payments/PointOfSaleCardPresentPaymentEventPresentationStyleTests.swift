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
        let dependencies = PointOfSaleCardPresentPaymentEventPresentationStyleDeterminer.Dependencies(
            tryPaymentAgainBackToCheckoutAction: {},
            nonRetryableErrorExitAction: {},
            formattedOrderTotalPrice: nil)

        // When
        let presentationStyle =  PointOfSaleCardPresentPaymentEventPresentationStyleDeterminer.presentationStyle(
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
        let dependencies = PointOfSaleCardPresentPaymentEventPresentationStyleDeterminer.Dependencies(
            tryPaymentAgainBackToCheckoutAction: { spyBackToCheckoutCalled = true },
            nonRetryableErrorExitAction: {},
            formattedOrderTotalPrice: nil)

        // When
        let presentationStyle =  PointOfSaleCardPresentPaymentEventPresentationStyleDeterminer.presentationStyle(
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
        let dependencies = PointOfSaleCardPresentPaymentEventPresentationStyleDeterminer.Dependencies(
            tryPaymentAgainBackToCheckoutAction: {},
            nonRetryableErrorExitAction: { spyTryAnotherPaymentMethod = true },
            formattedOrderTotalPrice: nil)

        // When
        let presentationStyle =  PointOfSaleCardPresentPaymentEventPresentationStyleDeterminer.presentationStyle(
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
        let dependencies = PointOfSaleCardPresentPaymentEventPresentationStyleDeterminer.Dependencies(
            tryPaymentAgainBackToCheckoutAction: {},
            nonRetryableErrorExitAction: {},
            formattedOrderTotalPrice: "$200.50")

        // When
        let presentationStyle = PointOfSaleCardPresentPaymentEventPresentationStyleDeterminer.presentationStyle(
            for: eventDetails,
            dependencies: dependencies)

        // Then
        guard case .message(.paymentSuccess(let viewModel)) = presentationStyle else {
            return XCTFail("Expected payment success message not found")
        }

        XCTAssertEqual(viewModel.message, "A payment of $200.50 was successfully made")
    }

}
