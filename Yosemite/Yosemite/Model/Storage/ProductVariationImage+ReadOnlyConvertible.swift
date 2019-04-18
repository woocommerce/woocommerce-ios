import Foundation
import Storage


// MARK: - Storage.ProductVariationImage: ReadOnlyConvertible
//
extension Storage.ProductVariationImage: ReadOnlyConvertible {

    /// Updates the Storage.ProductVariationImage with the ReadOnly.
    ///
    /// Note: We don't expose `ProductVariationImage` to the layers above Yosemite,
    /// so that's why we are updating with `ProductImage`.
    ///
    public func update(with image: Yosemite.ProductImage) {
        imageID = Int64(image.imageID)
        dateCreated = image.dateCreated
        dateModified = image.dateModified
        src = image.src
        name = image.name
        alt = image.alt
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    /// Note: We don't expose `ProductVariationImage` to the layers above Yosemite, so we are returning `ProductImage` here.
    ///
    public func toReadOnly() -> Yosemite.ProductImage {
        return ProductImage(imageID: Int(imageID),
                            dateCreated: dateCreated,
                            dateModified: dateModified,
                            src: src,
                            name: name,
                            alt: alt)
    }
}
