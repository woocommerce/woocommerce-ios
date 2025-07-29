import Foundation
import Storage

// MARK: - Storage.ProductAttributeTerm: ReadOnlyConvertible
//
extension Storage.ProductAttributeTerm: ReadOnlyConvertible {

    /// Updates the Storage.ProductAttributeTerm with the ReadOnly.
    ///
    public func update(with term: Yosemite.ProductAttributeTerm) {
        siteID = term.siteID
        termID = term.termID
        name = term.name
        slug = term.slug
        count = (Int32)(term.count)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductAttributeTerm {
        return ProductAttributeTerm(siteID: siteID,
                                    termID: termID,
                                    name: name ?? "",
                                    slug: slug ?? "",
                                    count: (Int)(count))
    }
}

// MARK: - Storage.ProductAttributeTerm: ListItemConvertible
//
extension Storage.ProductAttributeTerm: ListItemConvertible {
    public func toListItem() -> Yosemite.ProductAttributeTerm {
        return toReadOnly()
    }
}
