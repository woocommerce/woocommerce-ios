import Foundation
import Networking


/// ProductAction: Defines all of the Actions supported by the ProductStore.
///
public enum ProductAction: Action {

    /// Searches products that contain a given keyword.
    ///
    case searchProducts(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, excludedProductIDs: [Int64] = [], onCompletion: (Error?) -> Void)

    /// Synchronizes the Products matching the specified criteria.
    ///
    /// - Parameter onCompletion: called when sync completes, returns an error or a boolean that indicates whether there might be more products to sync.
    ///
    case synchronizeProducts(siteID: Int64,
        pageNumber: Int,
        pageSize: Int,
        stockStatus: ProductStockStatus?,
        productStatus: ProductStatus?,
        productType: ProductType?,
        sortOrder: ProductsSortOrder,
        excludedProductIDs: [Int64] = [],
        shouldDeleteStoredProductsOnFirstPage: Bool = true,
        onCompletion: (Result<Bool, Error>) -> Void)

    /// Retrieves the specified Product.
    ///
    case retrieveProduct(siteID: Int64, productID: Int64, onCompletion: (Result<Product, Error>) -> Void)

    /// Retrieves a specified list of Products.
    ///
    /// - Parameter onCompletion: called when retrieval for a page completes, returns an error or a tuple of a list of products and a boolean that
    ///                           indicates whether there might be more products to fetch.
    ///
    case retrieveProducts(siteID: Int64,
        productIDs: [Int64],
        pageNumber: Int = ProductsRemote.Default.pageNumber,
        pageSize: Int = ProductsRemote.Default.pageSize,
        onCompletion: (Result<(products: [Product], hasNextPage: Bool), Error>) -> Void)

    /// Deletes all of the cached products.
    ///
    case resetStoredProducts(onCompletion: () -> Void)

    /// Requests the Products found in a specified Order.
    ///
    case requestMissingProducts(for: Order, onCompletion: (Error?) -> Void)

    /// Adds a new Product.
    ///
    case addProduct(product: Product, onCompletion: (Result<Product, ProductUpdateError>) -> Void)

    /// Delete an existing Product.
    ///
    case deleteProduct(siteID: Int64, productID: Int64, onCompletion: (Result<Product, ProductUpdateError>) -> Void)

    /// Updates a specified Product.
    ///
    case updateProduct(product: Product, onCompletion: (Result<Product, ProductUpdateError>) -> Void)

    /// Checks whether a Product SKU is valid against other Products in the store.
    ///
    case validateProductSKU(_ sku: String?, siteID: Int64, onCompletion: (Bool) -> Void)

    /// Upserts a product in our local storage
    ///
    case replaceProductLocally(product: Product, onCompletion: () -> Void)
}
