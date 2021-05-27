/// Models a line in the receipt.
/// To be implemented in https://github.com/woocommerce/woocommerce-ios/issues/3978
public struct ReceiptLineItem: Codable {
    public let title: String
    public let quantity: String
    public let amount: String

    public init(title: String, quantity: String, amount: String) {
        self.title = title
        self.quantity = quantity
        self.amount = amount
    }
}

extension ReceiptLineItem {
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case quantity = "quantity"
        case amount = "amount"
    }
}
