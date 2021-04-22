/// Models the content of the receipt.
/// To be fully implemented in https://github.com/woocommerce/woocommerce-ios/issues/3978
public struct ReceiptContent {
    public let lineItems: [ReceiptLineItem]
    public let parameters: CardPresentReceiptParameters

    public init(parameters: CardPresentReceiptParameters, lineItems: [ReceiptLineItem] = []) {
        self.lineItems = lineItems
        self.parameters = parameters
    }
}
