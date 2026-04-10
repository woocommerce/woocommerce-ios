/// Models the various (sub)totals for a reciept
///
public struct ReceiptTotalLine: Codable {
    public let description: String
    public let amount: String

    public init(description: String, amount: String) {
        self.description = description
        self.amount = amount
    }
}

extension ReceiptTotalLine {
    enum CodingKeys: String, CodingKey {
        case description = "description"
        case amount = "amount"
    }
}
