import Foundation

public extension Array where Element == POSRefundItem {
    /// Calculates the total refunded quantity for each original order item ID.
    /// Note: API returns negative quantities for refunds, so we use abs().
    func refundedQuantitiesByItemID() -> [Int64: Int] {
        var quantities: [Int64: Int] = [:]
        for item in self {
            guard let itemID = item.refundedItemID else { continue }
            let quantity = NSDecimalNumber(decimal: abs(item.quantity)).intValue
            quantities[itemID, default: 0] += quantity
        }
        return quantities
    }
}
