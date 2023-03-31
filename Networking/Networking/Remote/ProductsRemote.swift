import Foundation

/// Protocol for `ProductsRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol ProductsRemoteProtocol {
    func addProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void)
    func deleteProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void)
    func loadProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void)
    func loadProducts(for siteID: Int64, by productIDs: [Int64], pageNumber: Int, pageSize: Int, completion: @escaping (Result<[Product], Error>) -> Void)
    func loadAllProducts(for siteID: Int64,
                         context: String?,
                         pageNumber: Int,
                         pageSize: Int,
                         stockStatus: ProductStockStatus?,
                         productStatus: ProductStatus?,
                         productType: ProductType?,
                         productCategory: ProductCategory?,
                         orderBy: ProductsRemote.OrderKey,
                         order: ProductsRemote.Order,
                         excludedProductIDs: [Int64],
                         completion: @escaping (Result<[Product], Error>) -> Void)
    func searchProducts(for siteID: Int64,
                        keyword: String,
                        pageNumber: Int,
                        pageSize: Int,
                        stockStatus: ProductStockStatus?,
                        productStatus: ProductStatus?,
                        productType: ProductType?,
                        productCategory: ProductCategory?,
                        excludedProductIDs: [Int64],
                        completion: @escaping (Result<[Product], Error>) -> Void)
    func searchProductsBySKU(for siteID: Int64,
                             keyword: String,
                             pageNumber: Int,
                             pageSize: Int,
                             completion: @escaping (Result<[Product], Error>) -> Void)
    func searchSku(for siteID: Int64,
                   sku: String,
                   completion: @escaping (Result<String, Error>) -> Void)
    func updateProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void)
    func updateProductImages(siteID: Int64, productID: Int64, images: [ProductImage], completion: @escaping (Result<Product, Error>) -> Void)
    func updateProducts(siteID: Int64, products: [Product], completion: @escaping (Result<[Product], Error>) -> Void)
    func loadProductIDs(for siteID: Int64, pageNumber: Int, pageSize: Int, completion: @escaping (Result<[Int64], Error>) -> Void)
    func createTemplateProduct(for siteID: Int64, template: ProductsRemote.TemplateType, completion: @escaping (Result<Int64, Error>) -> Void)
    func generateProductDescription(siteID: Int64, base: String) async throws -> String
}

extension ProductsRemoteProtocol {
    public func loadProducts(for siteID: Int64, by productIDs: [Int64], completion: @escaping (Result<[Product], Error>) -> Void) {
        loadProducts(for: siteID,
                     by: productIDs,
                     pageNumber: ProductsRemote.Default.pageNumber,
                     pageSize: ProductsRemote.Default.pageSize,
                     completion: completion)
    }
}

/// Product: Remote Endpoints
///
public final class ProductsRemote: Remote, ProductsRemoteProtocol {

    // MARK: - Products

    /// Adds a specific `Product`.
    ///
    /// - Parameters:
    ///     - product: the Product to be created remotely.
    ///     - completion: executed upon completion.
    ///
    public func addProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void) {
        do {
            let parameters = try product.toDictionary()
            let siteID = product.siteID
            let path = Path.products
            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
            let mapper = ProductMapper(siteID: siteID)
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Deletes a specific `Product`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll delete the remote product.
    ///     - productID: the ID of the Product to be deleted remotely.
    ///     - completion: executed upon completion.
    ///
    public func deleteProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void) {
        let path = "\(Path.products)/\(productID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .delete, siteID: siteID, path: path, parameters: nil, availableAsRESTRequest: true)
        let mapper = ProductMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the `Products` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is `edit`.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of products to be retrieved per page.
    ///     - stockStatus: Optional stock status filtering. Default to nil (no filtering).
    ///     - productStatus: Optional product status filtering. Default to nil (no filtering).
    ///     - productType: Optional product type filtering. Default to nil (no filtering).
    ///     - orderBy: the key to order the remote products. Default to product name.
    ///     - order: ascending or descending order. Default to ascending.
    ///     - excludedProductIDs: a list of product IDs to be excluded from the results.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProducts(for siteID: Int64,
                                context: String? = nil,
                                pageNumber: Int = Default.pageNumber,
                                pageSize: Int = Default.pageSize,
                                stockStatus: ProductStockStatus? = nil,
                                productStatus: ProductStatus? = nil,
                                productType: ProductType? = nil,
                                productCategory: ProductCategory? = nil,
                                orderBy: OrderKey = .name,
                                order: Order = .ascending,
                                excludedProductIDs: [Int64] = [],
                                completion: @escaping (Result<[Product], Error>) -> Void) {
        let stringOfExcludedProductIDs = excludedProductIDs.map { String($0) }
            .joined(separator: ",")

        let filterParameters = [
            ParameterKey.stockStatus: stockStatus?.rawValue ?? "",
            ParameterKey.productStatus: productStatus?.rawValue ?? "",
            ParameterKey.productType: productType?.rawValue ?? "",
            ParameterKey.category: filterProductCategoryParemeterValue(from: productCategory),
            ParameterKey.exclude: stringOfExcludedProductIDs
            ].filter({ $0.value.isEmpty == false })

        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context ?? Default.context,
            ParameterKey.orderBy: orderBy.value,
            ParameterKey.order: order.value
        ].merging(filterParameters, uniquingKeysWith: { (first, _) in first })

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ProductListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a specific list of `Product`s by `productID`.
    ///
    /// - Note: this method makes a single request for a list of products.
    ///         It is NOT a wrapper for `loadProduct()`
    ///
    /// - Parameters:
    ///     - siteID: We are fetching remote products for this site.
    ///     - productIDs: The array of product IDs that are requested.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of products to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProducts(for siteID: Int64,
                             by productIDs: [Int64],
                             pageNumber: Int = Default.pageNumber,
                             pageSize: Int = Default.pageSize,
                             completion: @escaping (Result<[Product], Error>) -> Void) {
        guard productIDs.isEmpty == false else {
            completion(.success([]))
            return
        }

        let stringOfProductIDs = productIDs.map { String($0) }
            .joined(separator: ",")
        let parameters = [
            ParameterKey.include: stringOfProductIDs,
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: Default.context
        ]
        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ProductListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }


    /// Retrieves a specific `Product`.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Product.
    ///     - productID: Identifier of the Product.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void) {
        let path = "\(Path.products)/\(productID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil, availableAsRESTRequest: true)
        let mapper = ProductMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the `Product`s available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products.
    ///     - keyword: Search string that should be matched by the products - title, excerpt and content (description).
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of products to be retrieved per page.
    ///     - excludedProductIDs: a list of product IDs to be excluded from the results.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func searchProducts(for siteID: Int64,
                               keyword: String,
                               pageNumber: Int,
                               pageSize: Int,
                               stockStatus: ProductStockStatus? = nil,
                               productStatus: ProductStatus? = nil,
                               productType: ProductType? = nil,
                               productCategory: ProductCategory? = nil,
                               excludedProductIDs: [Int64] = [],
                               completion: @escaping (Result<[Product], Error>) -> Void) {
        let stringOfExcludedProductIDs = excludedProductIDs.map { String($0) }
            .joined(separator: ",")

        let filterParameters = [
            ParameterKey.stockStatus: stockStatus?.rawValue ?? "",
            ParameterKey.productStatus: productStatus?.rawValue ?? "",
            ParameterKey.productType: productType?.rawValue ?? "",
            ParameterKey.category: filterProductCategoryParemeterValue(from: productCategory),
            ParameterKey.exclude: stringOfExcludedProductIDs
            ].filter({ $0.value.isEmpty == false })

        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.search: keyword,
            ParameterKey.exclude: stringOfExcludedProductIDs,
            ParameterKey.contextKey: Default.context
        ].merging(filterParameters, uniquingKeysWith: { (first, _) in first })

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ProductListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the `Product`s that match the SKU. Partial SKU search is supported for WooCommerce version 6.6+, otherwise full SKU match is performed.
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch remote products
    ///   - keyword: Search string that should be matched by the SKU (partial or full depending on the WC version).
    ///   - pageNumber: Number of page that should be retrieved.
    ///   - pageSize: Number of products to be retrieved per page.
    ///   - completion: Closure to be executed upon completion.
    public func searchProductsBySKU(for siteID: Int64,
                                    keyword: String,
                                    pageNumber: Int,
                                    pageSize: Int,
                                    completion: @escaping (Result<[Product], Error>) -> Void) {
        let parameters = [
            ParameterKey.sku: keyword,
            ParameterKey.partialSKUSearch: keyword,
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: Default.context
        ]
        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ProductListMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a product SKU if available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products.
    ///     - sku: Product SKU to search for.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func searchSku(for siteID: Int64,
                               sku: String,
                               completion: @escaping (Result<String, Error>) -> Void) {
        let parameters = [
            ParameterKey.sku: sku,
            ParameterKey.fields: ParameterValues.skuFieldValues
        ]

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ProductSkuMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates a specific `Product`.
    ///
    /// - Parameters:
    ///     - product: the Product to update remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void) {
        do {
            let parameters = try product.toDictionary()
            let productID = product.productID
            let siteID = product.siteID
            let path = "\(Path.products)/\(productID)"
            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
            let mapper = ProductMapper(siteID: siteID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    public func updateProductImages(siteID: Int64, productID: Int64, images: [ProductImage], completion: @escaping (Result<Product, Error>) -> Void) {
        do {
            let parameters = try ([ParameterKey.images: images]).toDictionary()
            let path = "\(Path.products)/\(productID)"
            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
            let mapper = ProductMapper(siteID: siteID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Updates provided `Products`.
    ///
    /// - Parameters:
    ///     - siteID: site which hosts the Products.
    ///     - products: the Products to update remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateProducts(siteID: Int64, products: [Product], completion: @escaping (Result<[Product], Error>) -> Void) {
        do {
            let parameters = try products.map { try $0.toDictionary() }
            let path = "\(Path.products)/batch"
            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: ["update": parameters],
                                         availableAsRESTRequest: true)
            let mapper = ProductsBulkUpdateMapper(siteID: siteID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Retrieves IDs for all of the `Products` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of products to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProductIDs(for siteID: Int64,
                               pageNumber: Int = Default.pageNumber,
                               pageSize: Int = Default.pageSize,
                               completion: @escaping (Result<[Int64], Error>) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.fields: ParameterKey.id
        ]

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ProductIDMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Creates a product using the provided template.
    /// Finishes with a completion block with the product ID.
    /// The created product has an `auto-draft` status.
    ///
    public func createTemplateProduct(for siteID: Int64, template: ProductsRemote.TemplateType, completion: @escaping (Result<Int64, Error>) -> Void) {
        let parameters = [ParameterKey.templateName: template.rawValue]
        let path = Path.templateProducts
        let request = JetpackRequest(wooApiVersion: .wcAdmin, method: .post, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = EntityIDMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    public func generateProductDescription(siteID: Int64, base: String) async throws -> String {
        let path = "sites/\(siteID)/jetpack-ai/completions"
        let parameters = ["content": base]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path, parameters: parameters)
        return try await enqueue(request)
    }
}


// MARK: - Constants
//
public extension ProductsRemote {
    enum OrderKey {
        case date
        case name
    }

    enum Order {
        case ascending
        case descending
    }

    /// Supported types for creating a template product.
    ///
    enum TemplateType: String {
        case physical
        case digital
        case variable
        case external
        case grouped
    }

    enum Default {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = Remote.Default.firstPageNumber
        public static let context: String = "edit"
    }

    private enum Path {
        static let products   = "products"
        static let templateProducts   = "onboarding/tasks/create_product_from_template"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
        static let exclude: String    = "exclude"
        static let include: String    = "include"
        static let search: String     = "search"
        static let orderBy: String    = "orderby"
        static let order: String      = "order"
        static let sku: String        = "sku"
        static let partialSKUSearch: String = "search_sku"
        static let productStatus: String = "status"
        static let productType: String = "type"
        static let stockStatus: String = "stock_status"
        static let category: String   = "category"
        static let fields: String     = "_fields"
        static let images: String = "images"
        static let id: String         = "id"
        static let templateName: String = "template_name"
    }

    private enum ParameterValues {
        static let skuFieldValues: String = "sku"
    }
}

private extension ProductsRemote {
    /// Returns the category Id in string format, or empty string if the product category is nil
    ///
    func filterProductCategoryParemeterValue(from productCategory: ProductCategory?) -> String {
        guard let productCategory = productCategory else {
            return ""
        }

        return String(productCategory.categoryID)
    }
}

private extension ProductsRemote.OrderKey {
    var value: String {
        switch self {
        case .date:
            return "date"
        case .name:
            return "title"
        }
    }
}

private extension ProductsRemote.Order {
    var value: String {
        switch self {
        case .ascending:
            return "asc"
        case .descending:
            return "desc"
        }
    }
}
