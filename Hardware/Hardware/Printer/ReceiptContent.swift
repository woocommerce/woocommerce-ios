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
        public static let productTotalLineDescription = NSLocalizedString(
            "Subtotal",
            comment: "Line description for 'Subtotal' cart total on the receipt. The subtotal of the products purchased before discounts.")

        public static let discountLineDescription = NSLocalizedString(
            "Discount %1$@",
            comment: "Line description for 'Discount' cart total on the receipt. Only shown when non-zero. %1$@ is the coupon code(s)")

        public static let feesLineDescription = NSLocalizedString(
            "Fees",
            comment: "Line description for 'Fees' cart total on the receipt. Only shown when non-zero."
        )

        public static let shippingLineDescription = NSLocalizedString(
            "Shipping",
            comment: "Line description for 'Shipping' cart total on the receipt. Only shown when non-zero"
        )

        public static let totalTaxLineDescription = NSLocalizedString(
            "Taxes",
            comment: "Line description for tax charged on the whole cart. Only shown when non-zero"
        )

        public static let amountPaidLineDescription = NSLocalizedString(
            "Amount Paid",
            comment: "Line description for 'Amount Paid' cart total on the receipt"
        )
    }
}
