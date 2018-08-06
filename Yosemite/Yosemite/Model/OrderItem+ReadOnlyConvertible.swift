import Foundation
import Storage


// MARK: - Storage.OrderItem: ReadOnlyConvertible
//
extension Storage.OrderItem: ReadOnlyConvertible {

    /// Indicates if the receiver is the Storage.Entity, backing up the specified ReadOnly.Entity.
    ///
    public func represents(readOnlyEntity: Any) -> Bool {
        guard let readOnlyItem = readOnlyEntity as? Yosemite.OrderItem else {
            return false
        }

// TODO: Add order.orderID + order.siteID Check
        return readOnlyItem.itemID == Int(itemID)
    }

    /// Updates the Storage.OrderItem with the ReadOnly.
    ///
    public func update(with orderItem: Yosemite.OrderItem) {
        itemID = Int64(orderItem.itemID)
        name = orderItem.name
        quantity = Int16(orderItem.quantity)
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
                         quantity: Int(quantity),
                         sku: sku ?? "",
                         subtotal: subtotal ?? "",
                         subtotalTax: subtotalTax ?? "",
                         taxClass: taxClass ?? "",
                         total: total ?? "",
                         totalTax: totalTax ?? "",
                         variationID: Int(variationID))
    }
}
