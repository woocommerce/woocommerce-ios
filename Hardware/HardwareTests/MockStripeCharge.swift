@testable import Hardware
import StripeTerminal
// This structs emulates the properties of SCPCharge
// We can not mock StripeTerminal.Reader directly, because its initializers
// are annotated as NS_UNAVAILABLE
struct MockStripeCharge {
    var stripeId: String
    var amount: UInt
    var currency: String
    var status: StripeTerminal.ChargeStatus
    var stripeDescription: String?
    var metadata: [AnyHashable: Any]
}

extension MockStripeCharge: StripeCharge {}

extension MockStripeCharge {
    static func mock() -> Self {
        MockStripeCharge(stripeId: "id",
                         amount: 16,
                         currency: "USD",
                         status: .succeeded,
                         stripeDescription: "A boat",
                         metadata: ["company": "woo"])
    }
}
