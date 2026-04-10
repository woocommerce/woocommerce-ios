import Foundation
import Storage

// Storage.Attribute: ReadOnlyConvertible Conformance.
//
extension Storage.GenericAttribute: ReadOnlyConvertible {

    /// Updates the Storage.Attribute with the a ReadOnly ProductVariationAttribute.
    ///
    public func update(with attribute: Yosemite.ProductVariationAttribute) {
        id = attribute.id
        key = attribute.name
        value = attribute.option
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductVariationAttribute {
        return ProductVariationAttribute(id: id,
                                         name: key,
                                         option: value)
    }
}
