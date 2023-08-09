import Foundation
import Storage

// MARK: - Storage.OrderItemProductAddOn: ReadOnlyConvertible
//
extension Storage.OrderItemProductAddOn: ReadOnlyConvertible {

    /// Updates the Storage.OrderItemProductAddOn with the a ReadOnly.
    ///
    public func update(with addOn: Yosemite.OrderItemProductAddOn) {
        addOnID = addOn.addOnID
        key = addOn.key
        value = addOn.value
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItemProductAddOn {
        .init(addOnID: addOnID, key: key, value: value)
    }
}
