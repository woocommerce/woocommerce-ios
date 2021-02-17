/// A PaymentIntent tracks the process of collecting a payment from your customer.
/// We would create exactly one PaymentIntent for each order
public struct PaymentIntent {
    /// Unique identifier for the PaymentIntent
    public let identifier: String

    /// The status of the Payment Intent
    public let status: PaymentIntentStatus

    /// When the PaymentIntent was created
    public let created: Date
    ///The amount to be collected by this PaymentIntent, provided in the currency’s smallest unit.
    /// - see: https://stripe.com/docs/currencies#zero-decimal
    public let amount: Int

    /// The currency of the payment.
    public let currency: String

    /// Set of key-value pairs attached to the object.
    public let metadata: [AnyHashable: Any]?

    // Charges that were created by this PaymentIntent, if any.
    public let charges: [Charge]
}


extension PaymentIntent: Equatable {
    public static func==(lhs: PaymentIntent, rhs: PaymentIntent) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
