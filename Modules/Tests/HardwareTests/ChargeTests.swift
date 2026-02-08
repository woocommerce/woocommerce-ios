import Testing
@testable import Hardware

/// Tests the mapping between Charge and SCPCharge
@Suite("Charge Tests")
struct ChargeTests {
    @Test func test_charge_maps_id() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.id == mockCharge.stripeId)
    }

    @Test func test_charge_maps_amount() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.amount == mockCharge.amount)
    }

    @Test func test_charge_maps_currency() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.currency == mockCharge.currency)
    }

    @Test func test_charge_maps_status() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.status == .succeeded)
    }

    @Test func test_charge_maps_description() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.description == mockCharge.stripeDescription)
    }

    @Test func test_charge_maps_metadata() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.metadata != nil)
        #expect(charge.metadata == mockCharge.metadata)
    }
}
