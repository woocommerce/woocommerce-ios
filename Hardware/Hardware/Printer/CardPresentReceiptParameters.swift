/// Encapsulates the information necessary to print a receipt for a
/// card present payment
public struct CardPresentReceiptParameters {
    /// The total amount
    public let amount: UInt

    /// The currency
    public let currency: String

    /// Metadata provided by the payment processor. Contains the data
    /// to be added to the receipt required by the card networks.
    public let cardDetails: CardPresentTransactionDetails

    public init(amount: UInt, currency: String, cardDetails: CardPresentTransactionDetails) {
        self.amount = amount
        self.currency = currency
        self.cardDetails = cardDetails
    }
}
