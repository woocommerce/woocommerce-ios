import Foundation

/// TODO This will soon be generated instead.

extension ProductImage {
    public func copy(
        imageID: CopiableProp<Int64> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        dateModified: NullableCopiableProp<Date> = .copy,
        src: CopiableProp<String> = .copy,
        name: NullableCopiableProp<String> = .copy,
        alt: NullableCopiableProp<String> = .copy
    ) -> ProductImage {
        /// Declare local variables because the Swift compiler will sometimes choke if there are
        /// too many arguments with default values.
        let imageID = imageID ?? self.imageID
        let dateCreated = dateCreated ?? self.dateCreated
        let dateModified = dateModified ?? self.dateModified
        let src = src ?? self.src
        let name = name ?? self.name
        let alt = alt ?? self.alt

        return ProductImage(
            imageID: imageID,
            dateCreated: dateCreated,
            dateModified: dateModified,
            src: src,
            name: name,
            alt: alt
        )
    }
}
