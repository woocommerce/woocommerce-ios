import Foundation
import Yosemite

/// Groups an order item and its quantity available for refund
///
struct RefundableOrderItem: Equatable {
    /// Original purchased item
    ///
    let item: OrderItem

    /// Current quantity available for refund
    ///
    let quantity: Int

    /// Saved refunds for this original order line, including their rounded monetary amounts.
    var refundedItems: [OrderItemRefund] = []
}

// MARK: Computed Properties
extension RefundableOrderItem {
    /// Quantity expressed as decimal
    ///
    func selecting(quantity: Int) -> RefundableOrderItem {
        var selected = RefundableOrderItem(item: item, quantity: quantity)
        selected.refundedItems = refundedItems
        return selected
    }

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
