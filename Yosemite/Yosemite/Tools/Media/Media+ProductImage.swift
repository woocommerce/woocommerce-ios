import Foundation

extension Media {
    /// Converts a `Media` to `ProductImage`.
    public var toProductImage: ProductImage {
        return ProductImage(imageID: mediaID,
                            dateCreated: date,
                            dateModified: date,
                            src: src,
                            name: name,
                            alt: alt)
    }
}
