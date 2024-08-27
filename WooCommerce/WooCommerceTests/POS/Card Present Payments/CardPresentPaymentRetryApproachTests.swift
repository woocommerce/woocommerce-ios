import XCTest
@testable import enum WooCommerce.CardPresentPaymentRetryApproach
import enum Yosemite.CardReaderServiceError
import enum Yosemite.CardReaderServiceUnderlyingError

final class CardPresentPaymentRetryApproachTests: XCTestCase {

    func test_init_genericError_uses_tryAgain() {
        // Given
        let error = NSError(domain: "generic", code: 123, userInfo: nil)

        // When
        let sut = CardPresentPaymentRetryApproach(error: error, retryAction: {})

        // Then
        guard case .tryAgain = sut else {
            return XCTFail("Unexpected retry approach, expected tryAgain, got \(sut)")
        }
    }

    func test_init_noActivePayment_uses_dontRetry() {
        // Given
        let error = CardReaderServiceError.retryNotPossibleNoActivePayment

        // When
        let sut = CardPresentPaymentRetryApproach(error: error, retryAction: {})

        // Then
        guard case .dontRetry = sut else {
            return XCTFail("Unexpected retry approach, expected dontRetry, got \(sut)")
        }
    }

    func test_init_paymentMethodCollection_unexpectedSDKError_uses_tryAgain() {
        // Given
        let error = CardReaderServiceError.paymentMethodCollection(
            underlyingError: .unexpectedSDKError)

        // When
        let sut = CardPresentPaymentRetryApproach(error: error, retryAction: {})

        // Then
        guard case .tryAgain = sut else {
            return XCTFail("Unexpected retry approach, expected tryAgain, got \(sut)")
        }
    }

    func test_init_paymentCapture_unexpectedSDKError_uses_tryAgain() {
        // Given
        let error = CardReaderServiceError.paymentCapture(
            underlyingError: .unexpectedSDKError)

        // When
        let sut = CardPresentPaymentRetryApproach(error: error, retryAction: {})

        // Then
        guard case .tryAgain = sut else {
            return XCTFail("Unexpected retry approach, expected tryAgain, got \(sut)")
        }
    }

    func test_init_paymentDeclinedByProcessor_uses_tryAnotherPaymentMethod() {
        // Given
        let error = CardReaderServiceError.paymentCapture(
            underlyingError: .paymentDeclinedByPaymentProcessorAPI(declineReason: .expiredCard))

        // When
        let sut = CardPresentPaymentRetryApproach(error: error, retryAction: {})

        // Then
        guard case .tryAnotherPaymentMethod = sut else {
            return XCTFail("Unexpected retry approach, expected tryAnotherPaymentMethod, got \(sut)")
        }
    }

    func test_init_paymentDeclinedByCardReader_uses_tryAnotherPaymentMethod() {
        // Given
        let error = CardReaderServiceError.paymentCapture(
            underlyingError: .paymentDeclinedByCardReader)

        // When
        let sut = CardPresentPaymentRetryApproach(error: error, retryAction: {})

        // Then
        guard case .tryAnotherPaymentMethod = sut else {
            return XCTFail("Unexpected retry approach, expected tryAnotherPaymentMethod, got \(sut)")
        }
    }

}
