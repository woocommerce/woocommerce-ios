/// Encapsulates the parameters needed to create a PaymentIntent
/// The Stripe Terminal SDK provides support for several parameters
/// i.e. metadata,onBehalfOf...
/// We will start with supporting the basics
public struct PaymentIntentParameters {
    /// The amount of the payment, provided in the currency’s smallest unit.
    /// Note: in testmode, only amounts ending in “00” will be approved. All other amounts will be declined by the Stripe API
    let amount: Int

    /// Three-letter ISO currency code, in lowercase. Must be a supported currency.
    let currency: String

    ///An arbitrary string attached to the object. If you send a receipt email for this payment, the email will include the description.
    let receiptDescription: String?

    /**
     * A string to be displayed on your customer’s credit card statement.
     * This may be up to 22 characters.
     * The statement descriptor must contain at least one letter, may not include <>"' characters,
     * and will appear on your customer’s statement in capital letters.
     * Non-ASCII characters are automatically stripped.
     * While most banks and card issuers display this information consistently, some may display it incorrectly or not at all.
     */
    let statementDescription: String?
}
