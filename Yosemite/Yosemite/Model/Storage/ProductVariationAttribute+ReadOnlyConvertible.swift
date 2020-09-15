import Foundation
import Storage

// Storage.FetchedAttribute: ReadOnlyConvertible Conformance.
//
extension Storage.FetchedAttribute: ReadOnlyConvertible {

    /// Updates the Storage.FetchedAttribute with the a ReadOnly ProductVariationAttribute.
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
