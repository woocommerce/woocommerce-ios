import XCTest
@testable import Hardware

/// Tests the mapping between Charge and SCPCharge
final class ChargeTests: XCTestCase {
    func test_charge_maps_id() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        XCTAssertEqual(charge.id, mockCharge.stripeId)
    }

    func test_charge_maps_amount() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        XCTAssertEqual(charge.amount, mockCharge.amount)
    }

    func test_charge_maps_currency() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        XCTAssertEqual(charge.currency, mockCharge.currency)
    }

    func test_charge_maps_status() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        XCTAssertEqual(charge.status, .succeeded)
    }

    func test_charge_maps_description() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        XCTAssertEqual(charge.description, mockCharge.stripeDescription)
    }

    func test_charge_maps_metadata() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        XCTAssertNotNil(charge.metadata)
        // Asserting keys only, as the metadata is types as [Hashable: Any]
        XCTAssertEqual(charge.metadata?.keys, mockCharge.metadata.keys)
    }
}
