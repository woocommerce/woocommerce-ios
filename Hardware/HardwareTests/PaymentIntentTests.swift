import XCTest
@testable import Hardware

/// Tests the mapping between PaymentIntent and SCPPaymentIntent
final class PaymentIntentTests: XCTestCase {
    func test_intent_maps_id() {
        let mockIntent = MockStripePaymentIntent.mock()
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.id, mockIntent.stripeId)
    }

    func test_intent_maps_status() {
        let mockIntent = MockStripePaymentIntent.mock()
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.status, .succeeded)
    }

    func test_intent_maps_date_created() {
        let mockIntent = MockStripePaymentIntent.mock()
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.created, mockIntent.created)
    }

    func test_intent_maps_amount() {
        let mockIntent = MockStripePaymentIntent.mock()
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.amount, mockIntent.amount)
    }

    func test_intent_maps_currency() {
        let mockIntent = MockStripePaymentIntent.mock()
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertEqual(intent.currency, mockIntent.currency)
    }

    func test_intent_maps_metadata() {
        let mockIntent = MockStripePaymentIntent.mock()
        let intent = PaymentIntent(intent: mockIntent)

        XCTAssertNil(intent.metadata)
    }

    func test_intent_maps_charges() {
        let mockIntent = MockStripePaymentIntent.mock()
        let intent = PaymentIntent(intent: mockIntent)

        // Very indirect test, that doesn't really test much.
        // It is not possible to instantiate a SCPCharge, which is what
        // would be needed to instantiate a mock intent.
        // For now, we will rely on counting charges as a way
        // to chek that at least both SCPPaymentIntent and
        // PaymentIntent reference the same number of charges 🤷
        XCTAssertEqual(intent.charges.count, mockIntent.charges.count)
    }
}
