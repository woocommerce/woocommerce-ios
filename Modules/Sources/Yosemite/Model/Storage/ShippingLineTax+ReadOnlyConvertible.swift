import Foundation
import Storage

// MARK: - Storage.ShippingLineTax: ReadOnlyConvertible
//
extension Storage.ShippingLineTax: ReadOnlyConvertible {

    /// Updates the Storage.ShippingLineRax with the ReadOnly type.
    ///
    public func update(with shippingLineTax: Yosemite.ShippingLineTax) {
        taxID = shippingLineTax.taxID
        subtotal = shippingLineTax.subtotal
        total = shippingLineTax.total
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLineTax {
        return ShippingLineTax(taxID: taxID, subtotal: subtotal ?? "", total: total ?? "")
    }
}
