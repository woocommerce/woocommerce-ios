import Foundation
import Storage


// MARK: - Storage.OrderItem: ReadOnlyConvertible
//
extension Storage.OrderItem: ReadOnlyConvertible {

    /// Updates the Storage.OrderItem with the ReadOnly.
    ///
    public func update(with orderItem: Yosemite.OrderItem) {
        itemID = Int64(orderItem.itemID)
        name = orderItem.name
        quantity = orderItem.quantity
        price = orderItem.price
        productID = Int64(orderItem.productID)
        sku = orderItem.sku
        subtotal = orderItem.subtotal
        subtotalTax = orderItem.subtotalTax
        taxClass = orderItem.taxClass
        total = orderItem.total
        totalTax = orderItem.totalTax
        variationID = Int64(orderItem.variationID)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItem {
        return OrderItem(itemID: Int(itemID),
                         name: name ?? "",
                         productID: Int(productID),
                         quantity: quantity,
                         price: price ?? NSDecimalNumber(integerLiteral: 0),
                         sku: sku,
                         subtotal: subtotal ?? "",
                         subtotalTax: subtotalTax ?? "",
                         taxClass: taxClass ?? "",
                         total: total ?? "",
                         totalTax: totalTax ?? "",
                         variationID: Int(variationID))
    }
}
