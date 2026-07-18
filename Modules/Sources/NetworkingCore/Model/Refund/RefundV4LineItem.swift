import Foundation

/// A single line of a v4 refund request (`POST /wc/v4/refunds` and `POST /wc/v4/refunds/preview`).
///
/// The v4 API expects exactly one of `quantity` (product lines — the server derives all monetary
/// values) or `refund_total` (fee/shipping lines — a tax-inclusive amount). Exclusivity is
/// enforced by construction: use the `quantityBased`/`amountBased` factory methods.
///
public struct RefundV4LineItem: Encodable, Equatable {
    /// The ID of the order line item being refunded.
    public let lineItemID: Int64

    /// Quantity to refund. Set only for product lines.
    public let quantity: Decimal?

    /// Tax-inclusive amount to refund. Set only for fee/shipping lines.
    public let refundTotal: Decimal?

    private init(lineItemID: Int64, quantity: Decimal?, refundTotal: Decimal?) {
        self.lineItemID = lineItemID
        self.quantity = quantity
        self.refundTotal = refundTotal
    }

    /// A product line refunded by quantity; the server calculates the refunded totals and taxes.
    public static func quantityBased(lineItemID: Int64, quantity: Decimal) -> RefundV4LineItem {
        RefundV4LineItem(lineItemID: lineItemID, quantity: quantity, refundTotal: nil)
    }

    /// A fee or shipping line refunded by a tax-inclusive amount.
    public static func amountBased(lineItemID: Int64, refundTotal: Decimal) -> RefundV4LineItem {
        RefundV4LineItem(lineItemID: lineItemID, quantity: nil, refundTotal: refundTotal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lineItemID, forKey: .lineItemID)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(refundTotal, forKey: .refundTotal)
    }

    private enum CodingKeys: String, CodingKey {
        case lineItemID = "line_item_id"
        case quantity
        case refundTotal = "refund_total"
    }
}
