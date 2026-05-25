import Foundation
import struct Yosemite.POSOrderCustomAmount
import struct Yosemite.POSOrderItem
import typealias Yosemite.OrderItemAttribute

struct POSRefundSelectableItem: Identifiable, Equatable {
    let itemID: Int64
    let name: String
    let imageSrc: String?
    let lineItemTotal: Decimal
    let totalTax: Decimal
    let originalQuantity: Decimal
    let formattedPrice: String
    let attributes: [OrderItemAttribute]
    /// `true` when this row represents a lump-sum line such as a custom amount / fee.
    /// Lump-sum rows have no quantity / unit-level breakdown — they refund as a single line.
    let isLumpSum: Bool
    var isSelected: Bool

    /// Unique identifier for the selectable item (combines itemID and index for multiple units)
    let id: String

    init(itemID: Int64,
         name: String,
         imageSrc: String?,
         lineItemTotal: Decimal,
         totalTax: Decimal,
         originalQuantity: Decimal,
         formattedPrice: String,
         attributes: [OrderItemAttribute],
         isLumpSum: Bool = false,
         isSelected: Bool,
         index: Int) {
        self.itemID = itemID
        self.name = name
        self.imageSrc = imageSrc
        self.lineItemTotal = lineItemTotal
        self.totalTax = totalTax
        self.originalQuantity = originalQuantity
        self.formattedPrice = formattedPrice
        self.attributes = attributes
        self.isLumpSum = isLumpSum
        self.isSelected = isSelected
        self.id = "\(itemID)-\(index)"
    }

    /// Creates a selectable item from a POSOrderItem.
    /// Stores the original total, totalTax and quantity for accurate refund calculations.
    init(from orderItem: POSOrderItem, isSelected: Bool, index: Int) {
        self.itemID = orderItem.itemID
        self.name = orderItem.name
        self.imageSrc = orderItem.imageSrc
        self.lineItemTotal = orderItem.total
        self.totalTax = orderItem.totalTax
        self.originalQuantity = orderItem.quantity
        self.formattedPrice = orderItem.formattedPrice
        self.attributes = orderItem.attributes
        self.isLumpSum = false
        self.isSelected = isSelected
        self.id = "\(orderItem.itemID)-\(index)"
    }

    /// Creates a selectable item from a POSOrderCustomAmount (a fee line on the order).
    /// Custom amounts refund as a single lump-sum line: no per-unit math, no attributes,
    /// no product image. `originalQuantity` is fixed at `1` so the calculator's
    /// full-refund branch returns `lineItemTotal` directly.
    init(from customAmount: POSOrderCustomAmount, isSelected: Bool) {
        self.itemID = customAmount.id
        self.name = customAmount.name
        self.imageSrc = nil
        self.lineItemTotal = customAmount.total
        self.totalTax = customAmount.totalTax
        self.originalQuantity = 1
        self.formattedPrice = customAmount.formattedTotal
        self.attributes = []
        self.isLumpSum = true
        self.isSelected = isSelected
        self.id = "fee-\(customAmount.id)"
    }
}
