import Foundation
import Storage


// MARK: - Storage.OrderItemRefund: ReadOnlyConvertible
//
extension Storage.OrderItemRefund: ReadOnlyConvertible {

    /// Updates the Storage.OrderItemRefund with the ReadOnly.
    ///
    public func update(with orderItemRefund: Yosemite.OrderItemRefund) {
        itemID = orderItemRefund.itemID
        name = orderItemRefund.name
        productID = orderItemRefund.productID
        variationID = orderItemRefund.variationID
        quantity = NSDecimalNumber(decimal: orderItemRefund.quantity)
        price = orderItemRefund.price
        sku = orderItemRefund.sku
        subtotal = orderItemRefund.subtotal
        subtotalTax = orderItemRefund.subtotalTax
        taxClass = orderItemRefund.taxClass
        total = orderItemRefund.total
        totalTax = orderItemRefund.totalTax
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItemRefund {
        let orderItemTaxesRefund = taxes?.map { $0.toReadOnly() } ?? [Yosemite.OrderItemTaxRefund]()

        return OrderItemRefund(itemID: itemID,
                               name: name ?? "",
                               productID: productID,
                               variationID: variationID,
                               quantity: quantity?.decimalValue ?? Decimal.zero,
                               price: price ?? NSDecimalNumber(integerLiteral: 0),
                               sku: sku,
                               subtotal: subtotal ?? "",
                               subtotalTax: subtotalTax ?? "",
                               taxClass: taxClass ?? "",
                               taxes: orderItemTaxesRefund,
                               total: total ?? "",
                               totalTax: totalTax ?? "")
    }
}
