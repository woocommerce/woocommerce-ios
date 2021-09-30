/// Models the various (sub)totals for a reciept
/// Named to match https://github.com/woocommerce/woocommerce/blob/4523dfdaccf9328d1a5834e324c85f1864fe751a/includes/class-wc-cart-totals.php#L27
public struct ReceiptCartTotals: Codable {
    public let totalTax: String

    public init(totalTax: String) {
        self.totalTax = totalTax
    }
}

extension ReceiptCartTotals {
    enum CodingKeys: String, CodingKey {
        case totalTax = "total_tax"
    }
}
