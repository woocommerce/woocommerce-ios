import Foundation
import Storage


// MARK: - Storage.ProductAttribute: ReadOnlyConvertible
//
extension Storage.ProductAttribute: ReadOnlyConvertible {

    /// Updates the Storage.ProductAttribute with the ReadOnly.
    ///
    public func update(with attribute: Yosemite.ProductAttribute) {
        attributeID = Int64(attribute.attributeID)
        name = attribute.name
        position = Int64(attribute.position)
        visible = attribute.visible
        variation = attribute.variation
        options = attribute.options
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductAttribute {
        return ProductAttribute(attributeID: Int64(attributeID),
                                name: name,
                                position: Int(position),
                                visible: visible,
                                variation: variation,
                                options: options ?? [String]())
    }
}
