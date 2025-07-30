import Foundation
import Storage


// MARK: - Storage.ProductDefaultAttribute: ReadOnlyConvertible
//
extension Storage.ProductDefaultAttribute: ReadOnlyConvertible {

    /// Updates the Storage.ProductDefaultAttribute with the ReadOnly.
    ///
    public func update(with defaultAttribute: Yosemite.ProductDefaultAttribute) {
        attributeID = defaultAttribute.attributeID
        name = defaultAttribute.name
        option = defaultAttribute.option
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductDefaultAttribute {
        return ProductDefaultAttribute(attributeID: attributeID,
                                       name: name,
                                       option: option)
    }
}
