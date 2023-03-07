import XCTest
@testable import Hardware

/// Tests the mapping between PaymentIntent and SCPPaymentIntent
final class PaymentIntentTests: XCTestCase {
    private let mockIntent = MockStripePaymentIntent.mock()

    func test_intent_maps_id() {
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.id, mockIntent.stripeId)
    }

    func test_intent_maps_status() {
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.status, .succeeded)
    }

    func test_intent_maps_date_created() {
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.created, mockIntent.created)
    }

    func test_intent_maps_amount() {
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.amount, mockIntent.amount)
    }

    func test_intent_maps_currency() {
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.currency, mockIntent.currency)
    }

    func test_intent_maps_metadata() {
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertNil(intent.metadata)
    }

    func test_intent_maps_charges() {
        let intent = PaymentIntent(intent: mockIntent)

        // Very indirect test, that doesn't really test much.
        // It is not possible to instantiate a SCPCharge, which is what
        // would be needed to instantiate a mock intent.
        // For now, we will rely on counting charges as a way
        // to check that at least both SCPPaymentIntent and
        // PaymentIntent reference the same number of charges 🤷
        XCTAssertEqual(intent.charges.count, mockIntent.charges.count)
    }

    func test_paymentMethod_is_nil_when_there_are_no_charges() {
        // When
        let intent = PaymentIntent(intent: mockIntent)

        // Then
        XCTAssertNil(intent.paymentMethod())
    }

    func test_paymentMethod_is_set_by_the_first_charge_when_there_are_two_charges() {
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
        XCTAssertEqual(intent.paymentMethod(), .card)
    }
}
