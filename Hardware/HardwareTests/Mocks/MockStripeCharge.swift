@testable import Hardware
import StripeTerminal
// This structs emulates the properties of SCPCharge
// We can not mock SCPCharge directly, because its initializers
// are annotated as NS_UNAVAILABLE
struct MockStripeCharge {
    let stripeId: String
    let amount: UInt
    let currency: String
    let status: StripeTerminal.ChargeStatus
    let stripeDescription: String?
    let metadata: [AnyHashable: Any]
    let paymentMethodDetails: StripeTerminal.PaymentMethodDetails?
}

extension MockStripeCharge: StripeCharge {}

extension MockStripeCharge {
    static func mock() -> Self {
        MockStripeCharge(stripeId: "id",
                         amount: 16,
                         currency: "USD",
                         status: .succeeded,
                         stripeDescription: "A boat",
                         metadata: ["company": "woo"],
                         paymentMethodDetails: nil)
    }
}
