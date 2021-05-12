/// Encapsulates the information necessary to print a receipt for a
/// card present payment
public struct CardPresentReceiptParameters: Codable {
    /// The total amount
    public let amount: UInt

    /// The currency
    public let currency: String

    /// The receipt date
    public let date: Date

    /// The store name
    public let storeName: String?

    /// Metadata provided by the payment processor. Contains the data
    /// to be added to the receipt required by the card networks.
    public let cardDetails: CardPresentTransactionDetails

    public init(amount: UInt,
                currency: String,
                date: Date,
                storeName: String?,
                cardDetails: CardPresentTransactionDetails) {
        self.amount = amount
        self.currency = currency
        self.date = date
        self.storeName = storeName
        self.cardDetails = cardDetails
    }
}

public extension CardPresentReceiptParameters {
    typealias MetadataKeys = PaymentIntent.MetadataKeys
}
