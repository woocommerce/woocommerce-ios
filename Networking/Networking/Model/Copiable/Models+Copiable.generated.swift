// Generated using Sourcery 0.18.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT



extension ProductCategory {
    public func copy(
        categoryID: CopiableProp<Int64> = .copy,
        siteID: CopiableProp<Int64> = .copy,
        parentID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        slug: CopiableProp<String> = .copy
    ) -> ProductCategory {
        let categoryID = categoryID ?? self.categoryID
        let siteID = siteID ?? self.siteID
        let parentID = parentID ?? self.parentID
        let name = name ?? self.name
        let slug = slug ?? self.slug

        return ProductCategory(
            categoryID: categoryID,
            siteID: siteID,
            parentID: parentID,
            name: name,
            slug: slug
        )
    }
}

extension ProductImage {
    public func copy(
        imageID: CopiableProp<Int64> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        dateModified: NullableCopiableProp<Date> = .copy,
        src: CopiableProp<String> = .copy,
        name: NullableCopiableProp<String> = .copy,
        alt: NullableCopiableProp<String> = .copy
    ) -> ProductImage {
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
