import Testing
@testable import Hardware
import StripeTerminal

struct `Underlying Error Stripe Tests` {

    @Test func `stripe stripeAPIDeclineCode used to determine decline reason`() {
        // Given
        let fakeStripeDeclineError = NSError(domain: ErrorDomain,
                                             code: ErrorCode.declinedByStripeAPI.rawValue,
                                             userInfo: [ErrorKey.stripeAPIDeclineCode.rawValue: "card_not_supported"])

        // When
        let sut = UnderlyingError(with: fakeStripeDeclineError)

        // Then
        let expectedError = UnderlyingError.paymentDeclinedByPaymentProcessorAPI(declineReason: .cardNotSupported)
        #expect(sut == expectedError)
    }
}
