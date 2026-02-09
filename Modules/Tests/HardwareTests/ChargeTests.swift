import Testing
@testable import Hardware

/// Tests the mapping between Charge and SCPCharge
struct `Charge Tests` {
    @Test func `charge maps id`() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.id == mockCharge.stripeId)
    }

    @Test func `charge maps amount`() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.amount == mockCharge.amount)
    }

    @Test func `charge maps currency`() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.currency == mockCharge.currency)
    }

    @Test func `charge maps status`() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.status == .succeeded)
    }

    @Test func `charge maps description`() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.description == mockCharge.stripeDescription)
    }

    @Test func `charge maps metadata`() {
        let mockCharge = MockStripeCharge.mock()
        let charge = Charge(charge: mockCharge)

        #expect(charge.metadata != nil)
        #expect(charge.metadata == mockCharge.metadata)
    }
}
