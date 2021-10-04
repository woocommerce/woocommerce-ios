/// Models the content of the receipt.
///
public struct ReceiptContent: Codable {
    public let lineItems: [ReceiptLineItem]
    public let parameters: CardPresentReceiptParameters
    public let cartTotals: [ReceiptTotalLine]

    public init(parameters: CardPresentReceiptParameters, lineItems: [ReceiptLineItem], cartTotals: [ReceiptTotalLine]) {
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

public extension ReceiptContent {
    enum Localization {
        public static let totalTaxLineDescription = NSLocalizedString(
            "Taxes",
            comment: "Line description for tax charged on the whole cart. Only shown when >0")

        public static let amountPaidLineDescription = NSLocalizedString(
            "Amount Paid",
            comment: "Line description for 'Amount Paid' cart total on the receipt"
        )
    }
}
