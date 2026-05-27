import Foundation

public struct POSRefundsResult {
    public let refunds: [POSRefund]
    public let isFullyRefunded: Bool
    public let supportsAutomaticRefund: Bool

    public init(refunds: [POSRefund], isFullyRefunded: Bool, supportsAutomaticRefund: Bool) {
        self.refunds = refunds
        self.isFullyRefunded = isFullyRefunded
        self.supportsAutomaticRefund = supportsAutomaticRefund
    }
}

public struct POSRefundRequest {
    public let orderID: Int64
    public let amount: Decimal
    public let reason: String?
    public let items: [POSRefundRequestItem]

    public init(orderID: Int64, amount: Decimal, reason: String?, items: [POSRefundRequestItem]) {
        self.orderID = orderID
        self.amount = amount
        self.reason = reason
        self.items = items
    }
}

public struct POSRefundRequestItem {
    public let itemID: Int64
    public let quantity: Int
    public let refundTotal: Decimal
    public let refundTax: Decimal

    public init(itemID: Int64, quantity: Int, refundTotal: Decimal, refundTax: Decimal) {
        self.itemID = itemID
        self.quantity = quantity
        self.refundTotal = refundTotal
        self.refundTax = refundTax
    }
}

public protocol POSRefundsServiceProtocol {
    func providePointOfSaleRefunds(for order: POSOrder) async throws -> POSRefundsResult
    func calculateRefundAmounts(for items: [POSRefundableItem]) -> POSRefundAmounts
    /// Creates a refund for the order.
    /// - Parameters:
    ///   - staffUserID: When non-nil, written to the refund's `meta_data` as
    ///     `_pos_staff_user_id` so the server's `pre_insert_shop_order_refund_object` hook can
    ///     attribute the refund timeline note to the current operator.
    ///   - overrideUserID: Set when a manager authorized the refund for a cashier. Written
    ///     as `_pos_override_user_id` so the server can record the approver alongside the
    ///     operator and emit a "POS: refund by X, approved by Y" note.
    ///   - overrideReason: The capability that triggered the override (e.g.
    ///     `"refund_shop_orders"`). Written as `_pos_override_reason`.
    func createRefund(orderID: Int64,
                      items: [POSRefundableItem],
                      reason: String?,
                      isAutomaticRefund: Bool,
                      staffUserID: Int64?,
                      overrideUserID: Int64?,
                      overrideReason: String?) async throws
    func loadOrderRefunds(for order: POSOrder) async throws -> [POSOrderRefund]
}
