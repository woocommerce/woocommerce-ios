#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension PaymentIntent {

    /// Convenience initializer. Fails when the Stripe intent id is nil or empty:
    /// since the Stripe SDK 3.0.0 the id is nullable to support offline payments,
    /// which the app does not support, so such an intent cannot be used.
    /// - Parameter intent: An instance of a StripeTerminal.PaymentIntent
    init?(intent: StripePaymentIntent) {
        guard let stripeId = intent.stripeId, !stripeId.isEmpty else {
            DDLogError("Failed to create a PaymentIntent. Intent ID is nil or empty: \(String(describing: intent.stripeId))")
            return nil
        }
        self.id = stripeId
        self.status = PaymentIntentStatus.with(status: intent.status)
        self.clientSecret = intent.clientSecret
        self.created = intent.created
        self.amount = intent.amount
        self.currency = intent.currency
        self.metadata = intent.metadata
        self.charges = intent.charges.map { .init(charge: $0) }
        self.collectedPaymentMethod = PaymentMethod(method: intent.paymentMethod)
    }
}

/// The initializers of StripeTerminal.PaymentIntent are annotated as NS_UNAVAILABLE
/// So we can not create instances of that class in our tests.
/// A workaround is declaring this protocol, which matches the parts of
/// SCPPaymentIntent that we are interested in, make Reader implement it,
/// and initialize Harware.CardReader with a type conforming to it.
protocol StripePaymentIntent {
    var stripeId: String? { get }
    var clientSecret: String? { get }
    var created: Date { get }
    var status: StripeTerminal.PaymentIntentStatus { get }
    var amount: UInt { get }
    var currency: String { get }
    var metadata: [String: String]? { get }
    var charges: [StripeTerminal.Charge] { get }
    var paymentMethod: StripeTerminal.PaymentMethod? { get }
}

extension StripeTerminal.PaymentIntent: StripePaymentIntent {}
#endif
