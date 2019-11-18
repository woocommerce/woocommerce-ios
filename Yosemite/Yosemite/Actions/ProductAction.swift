import Foundation
import Networking


/// ProductAction: Defines all of the Actions supported by the ProductStore.
///
public enum ProductAction: Action {

    /// Searches products that contain a given keyword.
    ///
    case searchProducts(siteID: Int, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Synchronizes the Products matching the specified criteria.
    ///
    case synchronizeProducts(siteID: Int, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Retrieves the specified Product.
    ///
    case retrieveProduct(siteID: Int, productID: Int, onCompletion: (Product?, Error?) -> Void)

    /// Retrieves a specified list of Products.
    ///
    case retrieveProducts(siteID: Int, productIDs: [Int], onCompletion: (Error?) -> Void)

    /// Deletes all of the cached products.
    ///
    case resetStoredProducts(onCompletion: () -> Void)

    /// Requests the Products found in a specified Order.
    ///
    case requestMissingProducts(for: Order, onCompletion: (Error?) -> Void)

    /// Updates the name of a specified Product.
    ///
    case updateProductName(siteID: Int, productID: Int, name: String?, onCompletion: (Product?, Error?) -> Void)

    /// Updates the description of a specified Product.
    ///
    case updateProductDescription(siteID: Int, productID: Int, description: String?, onCompletion: (Product?, Error?) -> Void)
}
