public struct ReceiptRegulatoryInfo {
    public let amount: UInt
    public let currency: String

    public init(amount: UInt, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}
