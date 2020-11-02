import Foundation
import Storage


// MARK: - Storage.OrderItem: ReadOnlyConvertible
//
extension Storage.OrderItem: ReadOnlyConvertible {

    /// Updates the Storage.OrderItem with the ReadOnly.
    ///
    public func update(with orderItem: Yosemite.OrderItem) {
        itemID = orderItem.itemID
        name = orderItem.name
        quantity = NSDecimalNumber(decimal: orderItem.quantity)
        price = orderItem.price
        productID = orderItem.productID
        sku = orderItem.sku
        subtotal = orderItem.subtotal
        subtotalTax = orderItem.subtotalTax
        taxClass = orderItem.taxClass
        total = orderItem.total
        totalTax = orderItem.totalTax
        variationID = orderItem.variationID
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItem {
        let orderItemTaxes = taxes?.map { $0.toReadOnly() }.sorted(by: { $0.taxID < $1.taxID }) ?? [Yosemite.OrderItemTax]()

        return OrderItem(itemID: itemID,
                         name: name ?? "",
                         productID: productID,
                         variationID: variationID,
                         quantity: quantity as Decimal,
                         price: price ?? NSDecimalNumber(integerLiteral: 0),
                         sku: sku,
                         subtotal: subtotal ?? "",
                         subtotalTax: subtotalTax ?? "",
                         taxClass: taxClass ?? "",
                         taxes: orderItemTaxes,
                         total: total ?? "",
                         totalTax: totalTax ?? "")
    }
}
