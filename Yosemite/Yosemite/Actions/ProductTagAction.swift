import Foundation
import Networking

/// ProductTagAction: Defines all of the Actions supported by the ProductTagStore.
///
public enum ProductTagAction: Action {

    /// Synchronizes all ProductTags matching the specified criteria.
    /// `onCompletion` will be invoked when the sync operation finishes.
    ///
    case synchronizeAllProductTags(siteID: Int64, fromPageNumber: Int = 1, onCompletion: (ProductTagActionError?) -> Void)


    /// Create new product tags associated with a given Site ID.
    /// `onCompletion` will be invoked when the add operation finishes.
    ///
    case addProductTags(siteID: Int64, tags: [String], onCompletion: (Result<[ProductTag], Error>) -> Void)


    /// Delete product tags associated with a given Site ID.
    /// `onCompletion` will be invoked when the add operation finishes.
    ///
    case deleteProductTags(siteID: Int64, ids: [Int64], onCompletion: (Result<[ProductTag], Error>) -> Void)

}

/// Defines all errors that a `ProductTagAction` can return
///
public enum ProductTagActionError {
    /// Represents a product tag synchronization failed state
    ///
    case tagsSynchronization(pageNumber: Int, rawError: Error)
}
