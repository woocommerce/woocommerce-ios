public struct ReceiptParameters {
    public let amount: UInt
    public let currency: String
    public let cardDetails: CardPresentDetails

    public init(amount: UInt, currency: String, cardDetails: CardPresentDetails) {
        self.amount = amount
        self.currency = currency
        self.cardDetails = cardDetails
    }
}
