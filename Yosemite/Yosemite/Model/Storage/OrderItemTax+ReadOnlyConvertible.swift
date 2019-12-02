import Foundation
import Storage


// MARK: - Storage.OrderItemTax: ReadOnlyConvertible
//
extension Storage.OrderItemTax: ReadOnlyConvertible {

    /// Updates the Storage.OrderItemTax with the ReadOnly.
    ///
    public func update(with orderItemTax: Yosemite.OrderItemTax) {
        taxID = Int64(orderItemTax.taxID)
        subtotal = orderItemTax.subtotal
        total = orderItemTax.total
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItemTax {
        return OrderItemTax(taxID: Int(taxID),
                            subtotal: subtotal ?? "",
                            total: total ?? "")
    }
}
