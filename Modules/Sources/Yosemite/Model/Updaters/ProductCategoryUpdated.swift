import Foundation

/// Product Category update functions
///
public protocol ProductCategoryUpdater {
    func parentIDUpdated(parentID: Int64) -> ProductCategory
}

extension ProductCategory: ProductCategoryUpdater {
    /// Update by mutating `parentID`
    ///
    public func parentIDUpdated(parentID: Int64) -> ProductCategory {
        return ProductCategory(categoryID: self.categoryID,
                               siteID: self.siteID,
                               parentID: parentID,
                               name: self.name,
                               slug: self.slug)
    }
}
