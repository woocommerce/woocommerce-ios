@testable import Hardware
import StripeTerminal
// This structs emulates the properties of SCPPaymentIntent
// We can not mock SCPPaymentIntent directly, because its initializers
// are annotated as NS_UNAVAILABLE
struct MockStripePaymentIntent {
    let stripeId: String
    let created: Date
    let status: StripeTerminal.PaymentIntentStatus
    let amount: UInt
    let currency: String
    let metadata: [AnyHashable: Any]?
    let charges: [StripeTerminal.Charge]
}

extension MockStripePaymentIntent: StripePaymentIntent {}

extension MockStripePaymentIntent {
    static func mock() -> Self {
        MockStripePaymentIntent(stripeId: "id",
                                created: Date(),
                                status: .succeeded,
                                amount: 100,
                                currency: "USD",
                                metadata: nil,
                                charges: [])
    }
}
