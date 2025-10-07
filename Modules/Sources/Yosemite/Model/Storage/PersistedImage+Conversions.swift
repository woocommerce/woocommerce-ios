import Foundation
import Storage

// MARK: - PersistedImage Conversions
public extension PersistedImage {
    /// Create a PersistedImage from a ProductImage
    static func make(from productImage: ProductImage, siteID: Int64) -> PersistedImage {
        return PersistedImage(
            siteID: siteID,
            id: productImage.imageID,
            dateCreated: productImage.dateCreated,
            dateModified: productImage.dateModified,
            src: productImage.src,
            name: productImage.name,
            alt: productImage.alt
        )
    }

    func toProductImage() -> ProductImage {
        return ProductImage(
            imageID: id,
            dateCreated: dateCreated,
            dateModified: dateModified,
            src: src,
            name: name,
            alt: alt
        )
    }
}
