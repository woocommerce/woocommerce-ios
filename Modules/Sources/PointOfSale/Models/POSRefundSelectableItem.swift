import Foundation
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
        self.isSelected = isSelected
        self.id = "\(orderItem.itemID)-\(index)"
    }
}
