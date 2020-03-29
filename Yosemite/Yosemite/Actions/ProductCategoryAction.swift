import Foundation
import Networking

/// ProductCategoryAction: Defines all of the Actions supported by the ProductCategoryStore.
///
public enum ProductCategoryAction: Action {

    /// Retrieve ProductCategories matching the specified criteria.
    ///
    case retrieveProductCategories(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: ([ProductCategory]?, Error?) -> Void)
}
