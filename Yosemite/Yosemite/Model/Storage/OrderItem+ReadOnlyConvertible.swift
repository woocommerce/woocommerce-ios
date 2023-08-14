import Foundation
import Storage

extension Storage.OrderItem {
    var attributesArray: [Storage.OrderItemAttribute] {
        return attributes?.toArray() ?? []
    }

    var addOnsArray: [Storage.OrderItemProductAddOn] {
        return productAddOns?.toArray() ?? []
    }
}

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
        parent = orderItem.parent.map { NSNumber(value: $0) }
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItem {
        let orderItemTaxes = taxes?.map { $0.toReadOnly() }.sorted(by: { $0.taxID < $1.taxID }) ?? [Yosemite.OrderItemTax]()
        let attributes = attributesArray.map { $0.toReadOnly() }
        let addOns = addOnsArray.map { $0.toReadOnly() }

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
                         totalTax: totalTax ?? "",
                         attributes: attributes,
                         addOns: addOns,
                         parent: parent?.int64Value)
    }
}
