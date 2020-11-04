import Foundation
import Storage


// MARK: - Storage.OrderItemAttribute: ReadOnlyConvertible
//
extension Storage.OrderItemAttribute: ReadOnlyConvertible {

    /// Updates the Storage.Account with the a ReadOnly.
    ///
    public func update(with attribute: Yosemite.OrderItemAttribute) {
        metaID = attribute.metaID
        name = attribute.name
        value = attribute.value
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderItemAttribute {
        return OrderItemAttribute(metaID: metaID, name: name, value: value)
    }
}
