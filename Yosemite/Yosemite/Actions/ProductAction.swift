import Foundation
import Networking


/// ProductAction: Defines all of the Actions supported by the ProductStore.
///
public enum ProductAction: Action {

    /// Searches products that contain a given keyword.
    ///
    case searchProducts(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Synchronizes the Products matching the specified criteria.
    ///
    case synchronizeProducts(siteID: Int64,
        pageNumber: Int,
        pageSize: Int,
        stockStatus: ProductStockStatus?,
        productStatus: ProductStatus?,
        productType: ProductType?,
        sortOrder: ProductsSortOrder,
        onCompletion: (Error?) -> Void)

    /// Retrieves the specified Product.
    ///
    case retrieveProduct(siteID: Int64, productID: Int64, onCompletion: (Product?, Error?) -> Void)

    /// Retrieves a specified list of Products.
    ///
    case retrieveProducts(siteID: Int64,
        productIDs: [Int64],
        pageNumber: Int = ProductsRemote.Default.pageNumber,
        pageSize: Int = ProductsRemote.Default.pageSize,
        onCompletion: (Result<[Product], Error>) -> Void)

    /// Deletes all of the cached products.
    ///
    case resetStoredProducts(onCompletion: () -> Void)

    /// Requests the Products found in a specified Order.
    ///
    case requestMissingProducts(for: Order, onCompletion: (Error?) -> Void)

    /// Updates a specified Product.
    ///
    case updateProduct(product: Product, onCompletion: (Product?, ProductUpdateError?) -> Void)

    /// Checks whether a Product SKU is valid against other Products in the store.
    ///
    case validateProductSKU(_ sku: String?, siteID: Int64, onCompletion: (Bool) -> Void)
}
