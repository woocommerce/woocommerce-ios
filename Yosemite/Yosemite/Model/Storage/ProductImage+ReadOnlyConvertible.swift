import Foundation
import Storage


// MARK: - Storage.ProductImage: ReadOnlyConvertible
//
extension Storage.ProductImage: ReadOnlyConvertible {

    /// Updates the Storage.ProductAttribute with the ReadOnly.
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
    public func toReadOnly() -> Yosemite.ProductImage {
        return ProductImage(imageID: Int64(imageID),
                            dateCreated: dateCreated,
                            dateModified: dateModified,
                            src: src,
                            name: name,
                            alt: alt)
    }
}
