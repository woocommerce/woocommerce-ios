import Foundation
import Storage


// MARK: - Storage.OrderItemRefund: ReadOnlyConvertible
//
extension Storage.OrderItemRefund: ReadOnlyConvertible {

    /// Updates the Storage.OrderItemRefund with the ReadOnly.
    ///
    public func update(with orderItemRefund: Yosemite.OrderItemRefund) {
        itemID = Int64(orderItemRefund.itemID)
        name = orderItemRefund.name
        productID = Int64(orderItemRefund.productID)
        variationID = Int64(orderItemRefund.variationID)
        quantity = orderItemRefund.quantity
        price = orderItemRefund.price
        sku = orderItemRefund.sku
        subtotal = orderItemRefund.subtotal
        subtotalTax = orderItemRefund.subtotalTax
        taxClass = orderItemRefund.taxClass
        refundTotal = orderItemRefund.refundTotal
        totalTax = orderItemRefund.totalTax
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItemRefund {
        let orderItemTaxesRefund = taxes?.map { $0.toReadOnly() } ?? [Yosemite.OrderItemTaxRefund]()

        return OrderItemRefund(itemID: Int(itemID),
                               name: name ?? "",
                               productID: Int(productID),
                               variationID: Int(variationID),
                               quantity: quantity,
                               price: price ?? NSDecimalNumber(integerLiteral: 0),
                               sku: sku,
                               subtotal: subtotal ?? "",
                               subtotalTax: subtotalTax ?? "",
                               taxClass: taxClass ?? "",
                               taxes: orderItemTaxesRefund,
                               refundTotal: refundTotal ?? "",
                               totalTax: totalTax ?? "")
    }
}
