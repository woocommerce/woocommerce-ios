/// Models a line in the receipt.
/// To be implemented in https://github.com/woocommerce/woocommerce-ios/issues/3978
public struct ReceiptLineItem {
    public let title: String
    public let amount: String

    public init(title: String, amount: String) {
        self.title = title
        self.amount = amount
    }
}
