/// Models the content of the receipt.
///
public struct ReceiptContent: Codable {
    public let lineItems: [ReceiptLineItem]
    public let parameters: CardPresentReceiptParameters
    public let cartTotals: ReceiptCartTotals

    public init(parameters: CardPresentReceiptParameters, lineItems: [ReceiptLineItem], cartTotals: ReceiptCartTotals) {
        self.lineItems = lineItems
        self.parameters = parameters
        self.cartTotals = cartTotals
    }
}

extension ReceiptContent {
    enum CodingKeys: String, CodingKey {
        case lineItems = "line_items"
        case parameters = "parameters"
        case cartTotals = "cart_totals"
    }
}
