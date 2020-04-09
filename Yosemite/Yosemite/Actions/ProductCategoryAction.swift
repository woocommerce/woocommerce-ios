import Foundation
import Networking

/// ProductCategoryAction: Defines all of the Actions supported by the ProductCategoryStore.
///
public enum ProductCategoryAction: Action {

    /// Synchronizes ProductCategories matching the specified criteria.
    ///
    case synchronizeProductCategories(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)
}
