@testable import Hardware
import StripeTerminal
// This structs emulates the properties of SCPPaymentIntent
// We can not mock SCPPaymentIntent directly, because its initializers
// are annotated as NS_UNAVAILABLE
struct MockStripePaymentIntent {
    let stripeId: String?
    let clientSecret: String?
    let created: Date
    let status: StripeTerminal.PaymentIntentStatus
    let amount: UInt
    let currency: String
    let metadata: [String: String]?
    let charges: [StripeTerminal.Charge]
    let paymentMethod: StripeTerminal.PaymentMethod?
}

extension MockStripePaymentIntent: StripePaymentIntent {}

extension MockStripePaymentIntent {
    static func mock(stripeId: String? = "id") -> Self {
        MockStripePaymentIntent(stripeId: stripeId,
                                clientSecret: "pi_secret",
                                created: Date(),
                                status: .succeeded,
                                amount: 100,
                                currency: "USD",
                                metadata: nil,
                                charges: [],
                                paymentMethod: nil)
    }
}
