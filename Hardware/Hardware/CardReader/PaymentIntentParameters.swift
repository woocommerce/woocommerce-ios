/// Encapsulates the parameters needed to create a PaymentIntent
/// The Stripe Terminal SDK provides support for several parameters
/// i.e. metadata,onBehalfOf...
/// We will start with supporting the basics
public struct PaymentIntentParameters {
    /// The amount of the payment.
    public let amount: Decimal

    /// Three-letter ISO currency code, in lowercase. Must be a supported currency.
    @CurrencyCode
    public private(set) var currency: String

    /// An arbitrary string attached to the object. If you send a receipt email for this payment, the email will include the description.
    public let receiptDescription: String?

    /**
     * A string to be displayed on your customer’s credit card statement.
     * This may be up to 22 characters.
     * The statement descriptor must contain at least one letter, may not include <>"' characters,
     * and will appear on your customer’s statement in capital letters.
     * Non-ASCII characters are automatically stripped.
     * While most banks and card issuers display this information consistently, some may display it incorrectly or not at all.
     */
    @StatementDescriptor
    public private(set) var statementDescription: String?

    /// Email address that the receipt for the resulting payment will be sent to.
    @Email
    public private(set) var receiptEmail: String?

    /// Set of key-value pairs that you can attach to an object.
    /// This can be useful for storing additional information about the object in a structured format.
    public let metadata: [AnyHashable: Any]?

    /// A Stripe issued customer ID
    /// See https://stripe.com/docs/api/customers
    ///
    public let customerID: String?

    /// Supported payment methods for this intent.
    ///
    /// Can be `card_present`, `interac_present`.
    ///
    public let paymentMethodTypes: [String]

    public init(amount: Decimal,
                currency: String,
                receiptDescription: String? = nil,
                statementDescription: String? = nil,
                receiptEmail: String? = nil,
                paymentMethodTypes: [String] = [],
                metadata: [AnyHashable: Any]? = nil,
                customerID: String? = nil) {
        self.amount = amount
        self.currency = currency
        self.receiptDescription = receiptDescription
        self.statementDescription = statementDescription
        self.receiptEmail = receiptEmail
        self.paymentMethodTypes = paymentMethodTypes
        self.metadata = metadata
        self.customerID = customerID
    }
}
