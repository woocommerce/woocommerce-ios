/// Encapsulates the information necessary to print a receipt for a
/// card present payment
public struct CardPresentReceiptParameters {
    /// The payment intent identifier
    public let paymentIntentID: String

    /// The total amount
    public let amount: UInt

    /// The currency
    public let currency: String

    /// The store name
    public let storeName: String?

    /// Metadata provided by the payment processor. Contains the data
    /// to be added to the receipt required by the card networks.
    public let cardDetails: CardPresentTransactionDetails

    public init(paymentIntentID: String,
                amount: UInt,
                currency: String,
                storeName: String?,
                cardDetails: CardPresentTransactionDetails) {
        self.paymentIntentID = paymentIntentID
        self.amount = amount
        self.currency = currency
        self.storeName = storeName
        self.cardDetails = cardDetails
    }
}

public extension CardPresentReceiptParameters {
    typealias MetadataKeys = PaymentIntent.MetadataKeys
}
