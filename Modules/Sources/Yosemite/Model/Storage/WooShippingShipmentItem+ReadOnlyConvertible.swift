import Foundation
import Storage

// Storage.WooShippingShipmentItem: ReadOnlyConvertible Conformance.
//
extension Storage.WooShippingShipmentItem: ReadOnlyConvertible {
    /// Updates the Storage.WooShippingShipmentItem with the a ReadOnly WooShippingShipmentItem.
    ///
    public func update(with savedItem: Yosemite.WooShippingShipmentItem) {
        self.id = savedItem.id
        self.subItems = savedItem.subItems as? NSArray
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooShippingShipmentItem {
        WooShippingShipmentItem(id: id, subItems: subItems as? [String])
    }
}
