import Foundation
import Networking


/// ProductAction: Defines all of the Actions supported by the ProductStore.
///
public enum ProductAction: Action {

    /// Synchronizes the Products matching the specified criteria.
    ///
    case synchronizeProducts(siteID: Int, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Retrieves the specified Product.
    ///
    case retrieveProduct(siteID: Int, productID: Int, onCompletion: (Product?, Error?) -> Void)

    /// Deletes all of the cached products.
    ///
    case resetStoredProducts(onCompletion: () -> Void)
}
