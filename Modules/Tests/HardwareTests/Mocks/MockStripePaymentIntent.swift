@testable import Hardware
import StripeTerminal
// This structs emulates the properties of SCPPaymentIntent
// We can not mock SCPPaymentIntent directly, because its initializers
// are annotated as NS_UNAVAILABLE
struct MockStripePaymentIntent {
    let stripeId: String?
    let created: Date
    let status: StripeTerminal.PaymentIntentStatus
    let amount: UInt
    let currency: String
    let metadata: [String: String]?
    let charges: [StripeTerminal.Charge]
}

extension MockStripePaymentIntent: StripePaymentIntent {
    // While SCPPaymentIntent `id` can be nullable in order to support offline payments
    // this is not the case for the app. PaymentIntent always need to have an associated `id`
    var id: String {
        stripeId ?? ""
    }
}

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
