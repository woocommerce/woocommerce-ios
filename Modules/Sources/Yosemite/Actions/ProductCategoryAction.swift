import Foundation
import Networking

/// ProductCategoryAction: Defines all of the Actions supported by the ProductCategoryStore.
///
public enum ProductCategoryAction: Action {

    /// Synchronizes all ProductCategories matching the specified criteria.
    /// `onCompletion` will be invoked when the sync operation finishes. `error` will be nil if the operation succeed.
    ///
    case synchronizeProductCategories(siteID: Int64, fromPageNumber: Int, onCompletion: (ProductCategoryActionError?) -> Void)

    /// Creates a new product category associated with a given Site ID.
    /// `onCompletion` will be invoked when the add operation finishes. `error` will be nil if the operation succeed.
    ///
    case addProductCategory(siteID: Int64, name: String, parentID: Int64?, onCompletion: (Result<ProductCategory, Error>) -> Void)

    /// Creates new product categories associated with a given Site ID, category names, and an optional parent ID
    /// `onCompletion` will be invoked when the add operation finishes.
    ///
    case addProductCategories(siteID: Int64, names: [String], parentID: Int64?, onCompletion: (Result<[ProductCategory], Error>) -> Void)

    /// Synchronizes the ProductCategory matching the specified categoryID.
    /// `onCompletion` will be invoked when the sync operation finishes. `error` will be nil if the operation succeed.
    ///
    case synchronizeProductCategory(siteID: Int64, categoryID: Int64, onCompletion: (Result<ProductCategory, Error>) -> Void)

    /// Updates an existing product category with the provided details.
    /// `onCompletion` will be invoked when the add operation finishes. `error` will be nil if the operation succeed.
    ///
    case updateProductCategory(_ category: ProductCategory, onCompletion: (Result<ProductCategory, Error>) -> Void)

    /// Deletes an existing product category with the provided site ID and category ID.
    /// `onCompletion` will be invoked when the add operation finishes. `error` will be nil if the operation succeed.
    ///
    case deleteProductCategory(siteID: Int64, categoryID: Int64, onCompletion: (Result<Void, Error>) -> Void)
}

/// Defines all errors that a `ProductCategoryAction` can return
///
public enum ProductCategoryActionError: Error {
    /// Represents a product category synchronization failed state
    ///
    case categoriesSynchronization(pageNumber: Int, rawError: Error)

    /// The requested category cannot be found remotely
    ///
    case categoryDoesNotExistRemotely

    /// A category with the same name already exists.
    ///
    case duplicateName
}

extension ProductCategoryActionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .duplicateName:
            return Localization.duplicateName
        case .categoriesSynchronization, .categoryDoesNotExistRemotely:
            return nil
        }
    }

    private enum Localization {
        static let duplicateName = NSLocalizedString(
            "productCategoryActionError.duplicateName",
            value: "A category with this name already exists. Please choose a different name.",
            comment: "Error shown when creating a product category with a name that already exists."
        )
    }
}
