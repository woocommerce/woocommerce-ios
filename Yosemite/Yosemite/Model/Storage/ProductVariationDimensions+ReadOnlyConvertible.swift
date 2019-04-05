import Foundation
import Storage


// MARK: - Storage.ProductVariationDimensions: ReadOnlyConvertible
//
extension Storage.ProductVariationDimensions: ReadOnlyConvertible {

    /// Updates the Storage.ProductVariationDimensions with the ReadOnly.
    ///
    /// Note: We don't expose `ProductVariationDimensions` to the layers above Yosemite,
    /// so that's why we are updating with `ProductDimensions`.
    ///
    public func update(with dimension: Yosemite.ProductDimensions) {
        length = dimension.length
        height = dimension.height
        width = dimension.width
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    /// Note: We don't expose `ProductVariationDimensions` to the layers above Yosemite, so we are returning `ProductDimensions` here.
    ///
    public func toReadOnly() -> Yosemite.ProductDimensions {
        return ProductDimensions(length: length, width: width, height: height)
    }
}
