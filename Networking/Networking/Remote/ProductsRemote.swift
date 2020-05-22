import Foundation

/// Protocol for `ProductsRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol ProductsEndpointsProviding {
    func loadProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void)
}

/// Product: Remote Endpoints
///
public final class ProductsRemote: Remote, ProductsEndpointsProviding {

    // MARK: - Products

    /// Retrieves all of the `Products` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of products to be retrieved per page.
    ///     - stockStatus: Optional stock status filtering. Default to nil (no filtering).
    ///     - productStatus: Optional product status filtering. Default to nil (no filtering).
    ///     - productType: Optional product type filtering. Default to nil (no filtering).
    ///     - orderBy: the key to order the remote products. Default to product name.
    ///     - order: ascending or descending order. Default to ascending.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProducts(for siteID: Int64,
                                context: String? = nil,
                                pageNumber: Int = Default.pageNumber,
                                pageSize: Int = Default.pageSize,
                                stockStatus: ProductStockStatus? = nil,
                                productStatus: ProductStatus? = nil,
                                productType: ProductType? = nil,
                                orderBy: OrderKey = .name,
                                order: Order = .ascending,
                                completion: @escaping ([Product]?, Error?) -> Void) {
        let filterParameters = [
            ParameterKey.stockStatus: stockStatus?.rawValue ?? "",
            ParameterKey.productStatus: productStatus?.rawValue ?? "",
            ParameterKey.productType: productType?.rawValue ?? ""
            ].filter({ $0.value.isEmpty == false })

        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context ?? Default.context,
            ParameterKey.orderBy: orderBy.value,
            ParameterKey.order: order.value
        ].merging(filterParameters, uniquingKeysWith: { (first, _) in first })

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
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
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProducts(for siteID: Int64, by productIDs: [Int64], completion: @escaping ([Product]?, Error?) -> Void) {
        let stringOfProductIDs = productIDs.map { String($0) }
            .filter { !$0.isEmpty }
            .joined(separator: ",")
        let parameters = [ ParameterKey.include: stringOfProductIDs ]
        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
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
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
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
    ///     - completion: Closure to be executed upon completion.
    ///
    public func searchProducts(for siteID: Int64,
                               keyword: String,
                               pageNumber: Int,
                               pageSize: Int,
                               completion: @escaping ([Product]?, Error?) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.search: keyword
        ]

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
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
                               completion: @escaping (String?, Error?) -> Void) {
        let parameters = [
            ParameterKey.sku: sku,
            ParameterKey.fields: ParameterValues.skuFieldValues
        ]

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductSkuMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates a specific `Product`.
    ///
    /// - Parameters:
    ///     - product: the Product to update remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateProduct(product: Product, completion: @escaping (Product?, Error?) -> Void) {
        do {
            let parameters = try product.toDictionary()
            let productID = product.productID
            let siteID = product.siteID
            let path = "\(Path.products)/\(productID)"
            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
            let mapper = ProductMapper(siteID: siteID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(nil, error)
        }
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

    enum Default {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = Remote.Default.firstPageNumber
        public static let context: String = "view"
    }

    private enum Path {
        static let products   = "products"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
        static let include: String    = "include"
        static let search: String     = "search"
        static let orderBy: String    = "orderby"
        static let order: String      = "order"
        static let sku: String        = "sku"
        static let productStatus: String = "status"
        static let productType: String = "type"
        static let stockStatus: String = "stock_status"
        static let fields: String     = "_fields"
    }

    private enum ParameterValues {
        static let skuFieldValues: String = "sku"
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
