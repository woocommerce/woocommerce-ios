import Testing
@testable import Hardware

/// Tests the mapping between PaymentIntent and SCPPaymentIntent
struct `Payment Intent Tests` {
    private let mockIntent = MockStripePaymentIntent.mock()

    @Test func `intent maps id`() {
        let intent = PaymentIntent(intent: mockIntent)

        #expect(intent.id == mockIntent.stripeId)
    }

    @Test func `intent maps status`() {
        let intent = PaymentIntent(intent: mockIntent)

        #expect(intent.status == .succeeded)
    }

    @Test func `intent maps date created`() {
        let intent = PaymentIntent(intent: mockIntent)

        #expect(intent.created == mockIntent.created)
    }

    @Test func `intent maps amount`() {
        let intent = PaymentIntent(intent: mockIntent)

        #expect(intent.amount == mockIntent.amount)
    }

    @Test func `intent maps currency`() {
        let intent = PaymentIntent(intent: mockIntent)

        #expect(intent.currency == mockIntent.currency)
    }

    @Test func `intent maps metadata`() {
        let intent = PaymentIntent(intent: mockIntent)

        #expect(intent.metadata == nil)
    }

    @Test func `intent maps charges`() {
        let intent = PaymentIntent(intent: mockIntent)

        // Very indirect test, that doesn't really test much.
        // It is not possible to instantiate a SCPCharge, which is what
        // would be needed to instantiate a mock intent.
        // For now, we will rely on counting charges as a way
        // to check that at least both SCPPaymentIntent and
        // PaymentIntent reference the same number of charges
        #expect(intent.charges.count == mockIntent.charges.count)
    }

    @Test func `paymentMethod is nil when there are no charges`() {
        // When
        let intent = PaymentIntent(intent: mockIntent)

        // Then
        #expect(intent.paymentMethod() == nil)
    }

    @Test func `paymentMethod is set by the first charge when there are two charges`() {
        // When
        let intent = PaymentIntent(id: "",
                                   status: .processing,
                                   created: .init(),
                                   amount: 1201,
                                   currency: "cad",
                                   metadata: nil,
                                   charges: [.init(id: "",
                                                   amount: 201,
                                                   currency: "cad",
                                                   status: .failed,
                                                   description: nil,
                                                   metadata: nil,
                                                   paymentMethod: .card),
                                             .init(id: "",
                                                   amount: 1000,
                                                   currency: "cad",
                                                   status: .failed,
                                                   description: nil,
                                                   metadata: nil,
                                                   paymentMethod: .unknown)])

        // Then
        #expect(intent.paymentMethod() == .card)
    }
}
