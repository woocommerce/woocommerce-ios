/// Encapsulates the information necessary to print a receipt for a
/// card present payment
public struct CardPresentReceiptParameters: Codable {
    /// The total amount
    public let amount: UInt

    /// The formatted amount for display purposes
    public let formattedAmount: String

    /// The currency
    public let currency: String

    /// The receipt date
    public let date: Date

    /// The store name
    public let storeName: String?

    /// Metadata provided by the payment processor. Contains the data
    /// to be added to the receipt required by the card networks.
    public let cardDetails: CardPresentTransactionDetails

    /// The order ID
    public let orderID: Int64?

    public init(amount: UInt,
                formattedAmount: String,
                currency: String,
                date: Date,
                storeName: String?,
                cardDetails: CardPresentTransactionDetails,
                orderID: Int64?) {
        self.amount = amount
        self.formattedAmount = formattedAmount
        self.currency = currency
        self.date = date
        self.storeName = storeName
        self.cardDetails = cardDetails
        self.orderID = orderID
    }
}

public extension CardPresentReceiptParameters {
    typealias MetadataKeys = PaymentIntent.MetadataKeys
}

extension CardPresentReceiptParameters {
    enum CodingKeys: String, CodingKey {
        case amount = "amount"
        case formattedAmount = "formatted_amount"
        case currency = "currency"
        case date = "date"
        case storeName = "store_name"
        case cardDetails = "card_details"
        case orderID = "order_id"
    }
}
