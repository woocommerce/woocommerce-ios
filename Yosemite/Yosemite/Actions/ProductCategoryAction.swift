import Foundation
import Networking

/// ProductCategoryAction: Defines all of the Actions supported by the ProductCategoryStore.
///
public enum ProductCategoryAction: Action {

    /// Synchronizes all ProductCategories matching the specified criteria.
    /// `onCompletion` will be invoked when the sync operation finishes. `error` will be nill if the operation succeed.
    ///
    case synchronizeProductCategories(siteID: Int64, fromPageNumber: Int, onCompletion: (ProductCategoryActionError?) -> Void)
}

/// Defines all errors that a `ProductCategoryAction` can return
///
public enum ProductCategoryActionError {
    
    /// Represents a product category synchronization failed state
    ///
    case categoriesSynchronization(pageNumber: Int, rawError: Error)
}
