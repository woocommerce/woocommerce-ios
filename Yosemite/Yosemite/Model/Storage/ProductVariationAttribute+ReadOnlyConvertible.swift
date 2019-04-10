import Foundation
import Storage


// MARK: - Storage.ProductVariationAttribute: ReadOnlyConvertible
//
extension Storage.ProductVariationAttribute: ReadOnlyConvertible {

    /// Updates the Storage.ProductAttribute with the ReadOnly.
    ///
    public func update(with attribute: Yosemite.ProductVariationAttribute) {
        attributeID = Int64(attribute.attributeID)
        name = attribute.name
        option = attribute.option
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductVariationAttribute {
        return ProductVariationAttribute(attributeID: Int(attributeID),
                                         name: name ?? "",
                                         option: option ?? "")
    }
}
