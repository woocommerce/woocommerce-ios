import Testing
@testable import Hardware

/// Tests the payment intent mapping helper of `StripeCardReaderService`.
struct StripeCardReaderServiceTests {
    @Test func test_capturedPaymentIntent_when_stripeId_is_present_then_returns_mapped_intent() throws {
        // Given
        let mockIntent = MockStripePaymentIntent.mock()

        // When
        let paymentIntent = try StripeCardReaderService.capturedPaymentIntent(from: mockIntent)

        // Then
        #expect(paymentIntent.id == mockIntent.stripeId)
    }

    @Test func test_capturedPaymentIntent_when_stripeId_is_nil_then_throws_paymentCapture_with_paymentIntentIdMissing() {
        // Given
        let mockIntent = MockStripePaymentIntent.mock(stripeId: nil)

        // When
        let error = #expect(throws: CardReaderServiceError.self) {
            try StripeCardReaderService.capturedPaymentIntent(from: mockIntent)
        }

        // Then
        guard case .paymentCapture(underlyingError: .paymentIntentIdMissing) = error else {
            Issue.record("Expected paymentCapture(.paymentIntentIdMissing), got \(String(describing: error))")
            return
        }
    }
}
