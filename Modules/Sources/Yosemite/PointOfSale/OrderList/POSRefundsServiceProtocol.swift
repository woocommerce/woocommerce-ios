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
    /// - Parameter staffUserID: When non-nil, written to the refund's `meta_data` as
    ///   `_pos_attribution` so the server's `pre_insert_shop_order_refund_object` hook can
    ///   attribute the refund timeline note to the current operator (mirrors order-side
    ///   attribution from the M1 plan).
    func createRefund(orderID: Int64, items: [POSRefundableItem], reason: String?, isAutomaticRefund: Bool, staffUserID: Int64?) async throws
    func loadOrderRefunds(for order: POSOrder) async throws -> [POSOrderRefund]
}
