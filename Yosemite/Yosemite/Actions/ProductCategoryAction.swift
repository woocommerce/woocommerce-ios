import Foundation
import Networking

/// ProductCategoryAction: Defines all of the Actions supported by the ProductCategoryStore.
///
public enum ProductCategoryAction: Action {

    /// Synchronizes ProductCategories matching the specified criteria.
    /// `onCompletion` will be invoked with either the `ProductCategories` fetched for the specific page or with an `error` if any.
    ///
    case synchronizeProductCategories(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: ([ProductCategory]?, Error?) -> Void)
}
