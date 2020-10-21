import Foundation
import Yosemite

/// Groups an order item and its quantity available for refund
///
struct RefundableOrderItem {
    /// Original purchased item
    ///
    let item: OrderItem

    /// Current quantity available for refund
    ///
    let quantity: Int
}

// MARK: Computed Properties
extension RefundableOrderItem {
    /// Quantity expressed as decimal
    ///
    var decimalQuantity: Decimal {
        Decimal(quantity)
    }
}

// MARK: Convenience Initializers
extension RefundableOrderItem {
    init(item: OrderItem, quantity: Decimal) {
        self.item = item
        self.quantity = Int(truncating: quantity as NSNumber)
    }
}
