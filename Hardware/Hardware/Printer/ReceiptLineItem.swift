/// Models a line in the receipt.
///
public struct ReceiptLineItem: Codable {
    public let title: String
    public let quantity: String
    public let amount: String
    public let attributes: [ReceiptLineAttribute]

    public init(title: String, quantity: String, amount: String, attributes: [ReceiptLineAttribute]) {
        self.title = title
        self.quantity = quantity
        self.amount = amount
        self.attributes = attributes
    }
}

public struct ReceiptLineAttribute: Codable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

extension ReceiptLineItem {
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case quantity = "quantity"
        case amount = "amount"
        case attributes = "attributes"
    }
}
