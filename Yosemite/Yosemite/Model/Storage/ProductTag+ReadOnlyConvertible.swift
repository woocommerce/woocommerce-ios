import Foundation
import Storage


// MARK: - Storage.ProductTag: ReadOnlyConvertible
//
extension Storage.ProductTag: ReadOnlyConvertible {

    /// Updates the Storage.ProductTag with the ReadOnly.
    ///
    public func update(with tag: Yosemite.ProductTag) {
        siteID = tag.siteID
        tagID = tag.tagID
        name = tag.name
        slug = tag.slug
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductTag {
        return ProductTag(siteID: siteID,
                          tagID: tagID,
                          name: name,
                          slug: slug)
    }
}
