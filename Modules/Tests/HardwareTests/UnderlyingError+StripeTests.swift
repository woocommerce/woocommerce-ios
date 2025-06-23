import XCTest
@testable import Hardware
import StripeTerminal

final class UnderlyingError_StripeTests: XCTestCase {

    func test_stripe_stripeAPIDeclineCode_used_to_determine_decline_reason() {
        // Given
        let fakeStripeDeclineError = NSError(domain: ErrorDomain,
                                             code: ErrorCode.declinedByStripeAPI.rawValue,
                                             userInfo: [ErrorKey.stripeAPIDeclineCode.rawValue: "card_not_supported"])

        // When
        let sut = UnderlyingError(with: fakeStripeDeclineError)

        // Then
        let expectedError = UnderlyingError.paymentDeclinedByPaymentProcessorAPI(declineReason: .cardNotSupported)
        XCTAssertEqual(sut, expectedError)
    }

}
