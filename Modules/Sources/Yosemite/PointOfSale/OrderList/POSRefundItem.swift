import Foundation

public struct POSRefundItem: Equatable, Hashable {
    /// The original order line item ID that was refunded.
    /// This matches the `itemID` on `POSOrderItem`.
    public let refundedItemID: Int64?
    public let quantity: Decimal

    public init(refundedItemID: Int64?, quantity: Decimal) {
        self.refundedItemID = refundedItemID
        self.quantity = quantity
    }
}
