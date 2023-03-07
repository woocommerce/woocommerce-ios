#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension Charge {

    /// Convenience initializer
    /// - Parameter charge: An instance of a StripeTerminal.SCPCharge
    init(charge: StripeCharge) {
        self.id = charge.stripeId
        self.amount = charge.amount
        self.currency = charge.currency
        self.status = ChargeStatus.with(status: charge.status)
        self.description = charge.stripeDescription
        self.metadata = charge.metadata
        self.paymentMethod = PaymentMethod(method: charge.paymentMethodDetails)
    }
}

/// The initializers of SCPCharge are annotated as NS_UNAVAILABLE
/// So we can not create instances of that class in our tests.
/// A workaround is declaring this protocol, which matches the parts of
/// SCPCharge that we are interested in, make Crahge implement it,
/// and initialize Harware.Charge with a type conforming to it.
protocol StripeCharge {
    var stripeId: String { get }
    var amount: UInt { get }
    var currency: String { get }
    var status: StripeTerminal.ChargeStatus { get }
    var stripeDescription: String? { get }
    var metadata: [AnyHashable: Any] { get }
    var paymentMethodDetails: StripeTerminal.PaymentMethodDetails? { get }
}


extension StripeTerminal.Charge: StripeCharge { }
#endif
