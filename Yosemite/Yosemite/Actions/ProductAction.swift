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

    /// Synchronizes the ProductVariations matching the specified criteria.
    ///
    case synchronizeProductVariations(siteID: Int, productID: Int, onCompletion: (Error?) -> Void)

    /// Retrieves the specified ProductVariation.
    ///
    case retrieveProductVariation(siteID: Int, productID: Int, variationID: Int, onCompletion: (ProductVariation?, Error?) -> Void)

    /// Nukes all of the cached products and product variations.
    ///
    case resetStoredProductsAndVariations(onCompletion: () -> Void)
}
