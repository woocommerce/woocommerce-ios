import Foundation
import Storage


// MARK: - Storage.OrderItemTaxRefund: ReadOnlyConvertible
//
extension Storage.OrderItemTaxRefund: ReadOnlyConvertible {

    /// Updates the Storage.OrderItemTax with the ReadOnly.
    ///
    public func update(with orderItemTaxRefund: Yosemite.OrderItemTaxRefund) {
        taxID = Int64(orderItemTaxRefund.taxID)
        subtotal = orderItemTaxRefund.subtotal
        total = orderItemTaxRefund.total
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItemTaxRefund {
        return OrderItemTaxRefund(taxID: Int64(taxID),
                                  subtotal: subtotal ?? "",
                                  total: total ?? "")
    }
}
