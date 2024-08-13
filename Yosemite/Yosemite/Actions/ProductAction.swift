import Foundation
import Networking

public enum SKUSearchResult {
    case product(Product)
    case variation(ProductVariation)
}

/// ProductAction: Defines all of the Actions supported by the ProductStore.
///
public enum ProductAction: Action {

    /// Searches products that contain a given keyword in the local database.
    ///
    /// - Parameter siteID: Site id of the products.
    /// - Parameter keyword: Keyword to search.
    /// - Parameter pageSize: They max amount of items to return.
    /// - Parameter onCompletion: Callback called when the action is finished, including a Boolean showing whether results were found.
    ///
    case searchProductsInCache(siteID: Int64,
                               keyword: String,
                               pageSize: Int,
                               onCompletion: (Bool) -> Void)

    /// Searches products that contain a given keyword.
    ///
    /// - Parameter onCompletion: called when sync completes, returns an error or a boolean that indicates whether there might be more products from search.
    ///
    case searchProducts(siteID: Int64,
                        keyword: String,
                        filter: ProductSearchFilter = .all,
                        pageNumber: Int,
                        pageSize: Int,
                        stockStatus: ProductStockStatus? = nil,
                        productStatus: ProductStatus? = nil,
                        productType: ProductType? = nil,
                        productCategory: ProductCategory? = nil,
                        excludedProductIDs: [Int64] = [],
                        onCompletion: (Result<Bool, Error>) -> Void)

    /// Synchronizes the Products matching the specified criteria.
    ///
    /// - Parameter onCompletion: called when sync completes, returns an error or a boolean that indicates whether there might be more products to sync.
    ///
    case synchronizeProducts(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int = ProductsRemote.Default.pageSize,
                             stockStatus: ProductStockStatus?,
                             productStatus: ProductStatus?,
                             productType: ProductType?,
                             productCategory: ProductCategory?,
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

    /// Retrieves the first Product with exact-match SKU
    ///
    case retrieveFirstPurchasableItemMatchFromSKU(siteID: Int64, sku: String, onCompletion: (Result<SKUSearchResult, Error>) -> Void)

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

    /// Updates a specified Product's images.
    ///
    case updateProductImages(siteID: Int64, productID: Int64, images: [ProductImage], onCompletion: (Result<Product, ProductUpdateError>) -> Void)

    /// Updates specified Products.
    ///
    case updateProducts(siteID: Int64, products: [Product], onCompletion: (Result<[Product], ProductUpdateError>) -> Void)

    /// Checks whether a Product SKU is valid against other Products in the store.
    ///
    case validateProductSKU(_ sku: String?, siteID: Int64, onCompletion: (Bool) -> Void)

    /// Upserts a product in our local storage
    ///
    case replaceProductLocally(product: Product, onCompletion: () -> Void)

    /// Checks if the store already has any products with the given status.
    /// Returns `false` if the store has no products.
    ///
    case checkIfStoreHasProducts(siteID: Int64,
                                 status: ProductStatus? = nil,
                                 onCompletion: (Result<Bool, Error>) -> Void)

    /// Identifies the language from the given string
    ///
    case identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature,
                          completion: (Result<String, Error>) -> Void)

    /// Generates a product name with Jetpack AI given the keywords
    ///
    case generateProductName(siteID: Int64,
                             keywords: String,
                             language: String,
                             completion: (Result<String, Error>) -> Void)

    /// Generates a product description with Jetpack AI given the name and features.
    ///
    case generateProductDescription(siteID: Int64,
                                    name: String,
                                    features: String,
                                    language: String,
                                    completion: (Result<String, Error>) -> Void)

    /// Generates a product sharing message with Jetpack AI given the URL, name, and description
    ///
    case generateProductSharingMessage(siteID: Int64,
                                       url: String,
                                       name: String,
                                       description: String,
                                       language: String,
                                       completion: (Result<String, Error>) -> Void)

    /// Generates product details (e.g. name and description) with Jetpack AI given the scanned texts from an image and optional product name .
    ///
    case generateProductDetails(siteID: Int64,
                                productName: String?,
                                scannedTexts: [String],
                                language: String,
                                completion: (Result<ProductDetailsFromScannedTexts, Error>) -> Void)

    /// Fetches the total number of products in the site given the site ID.
    ///
    case fetchNumberOfProducts(siteID: Int64, completion: (Result<Int64, Error>) -> Void)


    /// Generates a AIProduct using AI
    ///
    /// - Parameter siteID: Site ID for which the product is generated for
    /// - Parameter productName: Product name to input for AI
    /// - Parameter keywords: Keywords describing the product to input for AI
    /// - Parameter language: Language to generate the product details
    /// - Parameter tone: Tone of AI - Represented by `AIToneVoice`
    /// - Parameter currencySymbol: Currency symbol to generate product price
    /// - Parameter dimensionUnit: Weight unit to generate product dimensions
    /// - Parameter weightUnit: Weight unit to generate product weight
    /// - Parameter categories: Existing categories
    /// - Parameter tags: Existing tags
    /// - Parameter completion: Completion closure
    ///
    case generateAIProduct(siteID: Int64,
                           productName: String,
                           keywords: String,
                           language: String,
                           tone: String,
                           currencySymbol: String,
                           dimensionUnit: String?,
                           weightUnit: String?,
                           categories: [ProductCategory],
                           tags: [ProductTag],
                           completion: (Result<AIProduct, Error>) -> Void)

    /// Fetches stock based on the given status for a site
    /// - Parameter siteID: Site ID to fetch stock for.
    /// - Parameter stockType: Raw type of stock to query.
    /// - Parameter pageNumber: The index of the content page to query.
    /// - Parameter pageSize: The max amount of items to return per page.
    /// - Parameter orderBy: The key to sort returned items.
    /// - Parameter order: Whether to sort returned items ASC or DESC.
    /// - Parameter completion: Closure to trigger when fetching completes.
    ///
    case fetchStockReport(siteID: Int64,
                          stockType: String,
                          pageNumber: Int,
                          pageSize: Int,
                          order: ProductsRemote.Order,
                          completion: (Result<[ProductStock], Error>) -> Void)

    /// Fetches product reports for the given product ID of a site in a given time range.
    /// - Parameter siteID: Site ID to fetch stock for.
    /// - Parameter productIDs: IDs of the products of interest.
    /// - Parameter timeZone: The timezone to consider for the given time range.
    /// - Parameter earliestDateToInclude: The earliest date for the product reports.
    /// - Parameter latestDateToInclude: The latest date for the product reports.
    /// - Parameter pageNumber: The index of the content page to query.
    /// - Parameter pageSize: The max amount of items to return per page.
    /// - Parameter orderBy: The key to sort returned items.
    /// - Parameter order: Whether to sort returned items ASC or DESC.
    /// - Parameter completion: Closure to trigger when fetching completes.
    ///
    case fetchProductReports(siteID: Int64,
                             productIDs: [Int64],
                             timeZone: TimeZone,
                             earliestDateToInclude: Date,
                             latestDateToInclude: Date,
                             pageSize: Int,
                             pageNumber: Int,
                             orderBy: ProductsRemote.OrderKey,
                             order: ProductsRemote.Order,
                             completion: (Result<[ProductReport], Error>) -> Void)

    /// Fetches variation reports for the given product IDs and variation IDs in a given time range.
    /// - Parameter siteID: Site ID to fetch stock for.
    /// - Parameter productIDs: IDs of the products of interest.
    /// - Parameter timeZone: The timezone to consider for the given time range.
    /// - Parameter earliestDateToInclude: The earliest date for the product reports.
    /// - Parameter latestDateToInclude: The latest date for the product reports.
    /// - Parameter pageNumber: The index of the content page to query.
    /// - Parameter pageSize: The max amount of items to return per page.
    /// - Parameter orderBy: The key to sort returned items.
    /// - Parameter order: Whether to sort returned items ASC or DESC.
    /// - Parameter completion: Closure to trigger when fetching completes.
    ///
    case fetchVariationReports(siteID: Int64,
                               productIDs: [Int64],
                               variationIDs: [Int64],
                               timeZone: TimeZone,
                               earliestDateToInclude: Date,
                               latestDateToInclude: Date,
                               pageSize: Int,
                               pageNumber: Int,
                               orderBy: ProductsRemote.OrderKey,
                               order: ProductsRemote.Order,
                               completion: (Result<[ProductReport], Error>) -> Void)
}
