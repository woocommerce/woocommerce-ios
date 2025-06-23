import Foundation
import Storage

// MARK: - Storage.OrderItemProductAddOn: ReadOnlyConvertible
//
extension Storage.OrderItemProductAddOn: ReadOnlyConvertible {
    /// Updates the Storage.OrderItemProductAddOn with the a ReadOnly.
    ///
    public func update(with addOn: Yosemite.OrderItemProductAddOn) {
        addOnID = addOn.addOnID.map { NSNumber(value: $0) }
        key = addOn.key
        value = addOn.value
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItemProductAddOn {
        .init(addOnID: addOnID?.int64Value, key: key, value: value)
    }
}
