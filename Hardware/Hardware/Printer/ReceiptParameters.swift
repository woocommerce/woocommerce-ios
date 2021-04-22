/// Encapsulates the information necessary to print a receipt for a
/// card present payment
public struct ReceiptParameters {
    /// The total amount
    public let amount: UInt

    /// The currency
    public let currency: String

    /// Metadata provided by the payment processor. Contains the
    /// to be added to the receipt required by the card networks.
    public let cardDetails: CardPresentDetails

    public init(amount: UInt, currency: String, cardDetails: CardPresentDetails) {
        self.amount = amount
        self.currency = currency
        self.cardDetails = cardDetails
    }
}
