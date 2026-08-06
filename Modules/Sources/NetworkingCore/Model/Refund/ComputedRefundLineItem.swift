import Foundation

/// A single line of a server-computed refund creation request
/// (`POST /wc/v3/orders/{order_id}/refunds` with `compute_totals: true`, WC 11.1.0+).
///
/// Identical semantics to `RefundPreviewLineItem`, but the creation endpoint keys the order line
/// by `id` instead of `line_item_id`. The API expects exactly one of `quantity` (product lines —
/// the server derives all monetary values) or `refund_total` (fee/shipping lines — a tax-inclusive
/// amount). Exclusivity is enforced by construction: use the `quantityBased`/`amountBased`
/// factory methods.
///
public struct ComputedRefundLineItem: Encodable, Equatable {
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
    /// `refundTotal` is deliberately nil: the synthesized encoding omits it from the payload
    /// entirely, which is how the API distinguishes a quantity-based line.
    public static func quantityBased(lineItemID: Int64, quantity: Decimal) -> ComputedRefundLineItem {
        ComputedRefundLineItem(lineItemID: lineItemID, quantity: quantity, refundTotal: nil)
    }

    /// A fee or shipping line refunded by a tax-inclusive amount.
    /// `quantity` is deliberately nil: the synthesized encoding omits it from the payload
    /// entirely, which is how the API distinguishes an amount-based line.
    public static func amountBased(lineItemID: Int64, refundTotal: Decimal) -> ComputedRefundLineItem {
        ComputedRefundLineItem(lineItemID: lineItemID, quantity: nil, refundTotal: refundTotal)
    }

    // Encoding is synthesized: optionals encode via `encodeIfPresent`, so a nil `quantity` or
    // `refund_total` is omitted rather than sent as null.
    private enum CodingKeys: String, CodingKey {
        case lineItemID = "id"
        case quantity
        case refundTotal = "refund_total"
    }
}
