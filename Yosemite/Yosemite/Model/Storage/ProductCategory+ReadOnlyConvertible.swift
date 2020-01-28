import Foundation
import Storage


// MARK: - Storage.ProductCategory: ReadOnlyConvertible
//
extension Storage.ProductCategory: ReadOnlyConvertible {

    /// Updates the Storage.ProductCategory with the ReadOnly.
    ///
    public func update(with category: Yosemite.ProductCategory) {
        categoryID = category.categoryID
        name = category.name
        slug = category.slug
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductCategory {
        return ProductCategory(categoryID: categoryID,
                               name: name,
                               slug: slug)
    }
}
