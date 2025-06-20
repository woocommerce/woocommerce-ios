#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension PaymentIntent {

    /// Convenience initializer
    /// - Parameter intent: An instance of a StripeTerminal.PaymentIntent
    init(intent: StripePaymentIntent) {
        if let stripeId = intent.stripeId, !stripeId.isEmpty {
            self.id = stripeId
        } else {
            // Improvement: Ideally this initializer should be failable: https://github.com/woocommerce/woocommerce-ios/issues/11208
            DDLogError("Failed to create a PaymentIntent. Intent ID is nil or empty: \(String(describing: intent.stripeId))")
            self.id = ""
        }
        self.status = PaymentIntentStatus.with(status: intent.status)
        self.created = intent.created
        self.amount = intent.amount
        self.currency = intent.currency
        self.metadata = intent.metadata
        self.charges = intent.charges.map { .init(charge: $0) }
    }
}

/// The initializers of StripeTerminal.PaymentIntent are annotated as NS_UNAVAILABLE
/// So we can not create instances of that class in our tests.
/// A workaround is declaring this protocol, which matches the parts of
/// SCPPaymentIntent that we are interested in, make Reader implement it,
/// and initialize Harware.CardReader with a type conforming to it.
protocol StripePaymentIntent {
    var stripeId: String? { get }
    var created: Date { get }
    var status: StripeTerminal.PaymentIntentStatus { get }
    var amount: UInt { get }
    var currency: String { get }
    var metadata: [String: String]? { get }
    var charges: [StripeTerminal.Charge] { get }
}

/// StripePaymentIntent Conformance
///
/// Our implementation of PaymentIntent does not allow`id` to be nullable, as offline payments are not supported in the app.
/// This differs from StripeTerminal.PaymentIntent since 3.0.0, these can be nullable to support offline payments.
/// In order to not make our implementation accept a property that does not correspond to the app logic,
/// we provide an empty string if no stripeID can be found.
extension StripeTerminal.PaymentIntent: StripePaymentIntent {
    var id: String {
        stripeId ?? ""
    }
}
#endif
