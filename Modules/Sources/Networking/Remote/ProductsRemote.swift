import Foundation

/// Protocol for `ProductsRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol ProductsRemoteProtocol {
    func addProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void)
    func deleteProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void)
    func loadProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void)
    func loadProducts(for siteID: Int64, by productIDs: [Int64], pageNumber: Int, pageSize: Int) async throws -> [Product]
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
                         productIDs: [Int64],
                         excludedProductIDs: [Int64]) async throws -> [Product]
    func searchProducts(for siteID: Int64,
                        keyword: String,
                        searchFields: [ProductSearchField],
                        pageNumber: Int,
                        pageSize: Int,
                        stockStatus: ProductStockStatus?,
                        productStatus: ProductStatus?,
                        productType: ProductType?,
                        productCategory: ProductCategory?,
                        excludedProductIDs: [Int64]) async throws -> [Product]
    func searchProductsBySKU(for siteID: Int64,
                             keyword: String,
                             pageNumber: Int,
                             pageSize: Int) async throws -> [Product]
    func searchProductsByGlobalUniqueIdentifier(for siteID: Int64,
                             keyword: String,
                             pageNumber: Int,
                             pageSize: Int) async throws -> [Product]
    func searchSku(for siteID: Int64,
                   sku: String,
                   completion: @escaping (Result<String, Error>) -> Void)
    func updateProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void)
    func updateProductImages(siteID: Int64, productID: Int64, images: [ProductImage], completion: @escaping (Result<Product, Error>) -> Void)
    func updateProducts(siteID: Int64, products: [Product], completion: @escaping (Result<[Product], Error>) -> Void)
    func loadProductIDs(for siteID: Int64,
                        pageNumber: Int,
                        pageSize: Int,
                        productStatus: ProductStatus?,
                        productType: ProductType?,
                        completion: @escaping (Result<[Int64], Error>) -> Void)
    func loadNumberOfProducts(siteID: Int64) async throws -> Int64

    func loadStock(for siteID: Int64,
                   with stockType: String,
                   pageNumber: Int,
                   pageSize: Int,
                   order: ProductsRemote.Order) async throws -> [ProductStock]

    func loadProductReports(for siteID: Int64,
                            productIDs: [Int64],
                            timeZone: TimeZone,
                            earliestDateToInclude: Date,
                            latestDateToInclude: Date,
                            pageSize: Int,
                            pageNumber: Int,
                            orderBy: ProductsRemote.OrderKey,
                            order: ProductsRemote.Order) async throws -> [ProductReport]

    func loadVariationReports(for siteID: Int64,
                              productIDs: [Int64],
                              variationIDs: [Int64],
                              timeZone: TimeZone,
                              earliestDateToInclude: Date,
                              latestDateToInclude: Date,
                              pageSize: Int,
                              pageNumber: Int,
                              orderBy: ProductsRemote.OrderKey,
                              order: ProductsRemote.Order) async throws -> [ProductReport]

    func loadProductsForPointOfSale(for siteID: Int64,
                                    productTypes: [ProductType],
                                    pageNumber: Int) async throws -> PagedItems<POSProduct>

    func searchProductsForPointOfSale(for siteID: Int64,
                                      query: String,
                                      productTypes: [ProductType],
                                      pageNumber: Int) async throws -> PagedItems<POSProduct>

    func loadPopularProductsForPointOfSale(for siteID: Int64,
                                           productTypes: [ProductType],
                                           pageNumber: Int,
                                           perPage: Int) async throws -> PagedItems<POSProduct>

    func loadPOSProductByGlobalUniqueIdentifier(for siteID: Int64,
                                                   globalUniqueID: String) async throws -> POSProduct

    func loadPOSProduct(for siteID: Int64, productID: Int64) async throws -> POSProduct
}

extension ProductsRemoteProtocol {
    public func loadProducts(for siteID: Int64, by productIDs: [Int64]) async throws -> [Product] {
        try await loadProducts(for: siteID,
                               by: productIDs,
                               pageNumber: ProductsRemote.Default.pageNumber,
                               pageSize: ProductsRemote.Default.pageSize)
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
    ///     - productIDs: a list of product IDs to be included in the results. All products will be fetched if empty.
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
                                productIDs: [Int64] = [],
                                excludedProductIDs: [Int64] = []) async throws -> [Product] {
        let stringOfExcludedProductIDs = excludedProductIDs.map { String($0) }
            .joined(separator: ",")
        let stringOfProductIDs: String = {
            guard productIDs.isEmpty == false else {
                return ""
            }
            return productIDs.map { String($0) }
                .joined(separator: ",")
        }()


        let filterParameters = [
            ParameterKey.stockStatus: stockStatus?.rawValue ?? "",
            ParameterKey.productStatus: productStatus?.rawValue ?? "",
            ParameterKey.productType: productType?.rawValue ?? "",
            ParameterKey.category: filterProductCategoryParemeterValue(from: productCategory),
            ParameterKey.include: stringOfProductIDs,
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
        let mapper = ListMapper<Product>(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    /// Retrieves products for the Point of Sale. Simple and variable products are loaded for WC version 9.6+, otherwise only simple products are loaded.
    ///
    /// - Parameters:
    /// - siteID: Site for which we'll fetch remote products.
    /// - productTypes: A list of product types to be included in the results.
    /// - pageNumber: Index of page that should be retrieved.
    ///
    public func loadProductsForPointOfSale(for siteID: Int64,
                                           productTypes: [ProductType] = [.simple],
                                           pageNumber: Int = 1) async throws -> PagedItems<POSProduct> {
        let parameters = pointOfSaleProductFetchParameters(
            pageNumber: pageNumber,
            productTypes: productTypes)

        return try await makePagedPointOfSaleProductsRequest(
            for: siteID,
            pageNumber: pageNumber,
            parameters: parameters)
    }

    /// Loads popular products for Point of Sale
    ///
    /// - Parameters:
    ///   - siteID: The target site ID.
    ///   - productTypes: The product types to filter by.
    ///   - pageNumber: Number of page that should be retrieved.
    ///
    public func loadPopularProductsForPointOfSale(for siteID: Int64,
                                                  productTypes: [ProductType] = [.simple],
                                                  pageNumber: Int = 1,
                                                  perPage: Int = Default.pageSize) async throws -> PagedItems<POSProduct> {
        let parameters = pointOfSaleProductFetchParameters(
            pageNumber: pageNumber,
            productsPerPage: String(perPage),
            productTypes: productTypes,
            orderBy: .popularity,
            order: .descending
        )

        return try await makePagedPointOfSaleProductsRequest(
            for: siteID,
            pageNumber: pageNumber,
            parameters: parameters)
    }

    private func pointOfSaleProductFetchParameters(pageNumber: Int,
                                                   productsPerPage: String = POSConstants.productsPerPage,
                                                   productTypes: [ProductType],
                                                   orderBy: OrderKey = .name,
                                                   order: Order = .ascending) -> [String: any Hashable] {
        let parameters: [String: any Hashable] = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: productsPerPage,
            // When both productType and productTypes are provided, the productType is ignored in WC versions 9.6+.
            ParameterKey.productType: POSConstants.productType,
            ParameterKey.productTypes: productTypes.map { $0.rawValue }.joined(separator: ","),
            ParameterKey.orderBy: orderBy.value,
            ParameterKey.order: order.value,
            ParameterKey.productStatus: POSConstants.productStatus,
            ParameterKey.downloadable: String(false),
            ParameterKey.fields: POSProduct.requestFields.joined(separator: ","),
            ParameterKey.posProductsOnly: String(true)
        ]

        return parameters
    }

    private func makePagedPointOfSaleProductsRequest(for siteID: Int64,
                                                     pageNumber: Int,
                                                     parameters: [String: any Hashable]) async throws -> PagedItems<POSProduct> {
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.products,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ListMapper<POSProduct>(siteID: siteID)

        let (products, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)
        return createPagedItems(items: products, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }

    /// Remote search of products for the Point of Sale. Simple and variable products are loaded for WC version 9.6+, otherwise only simple products are loaded.
    /// `search` is used, which searches in `name`, `sku`, `globalUniqueID` fields.
    /// We also send `search_name_or_sku`, which will be used in preference to `search` when implemented on a site (in future.)
    ///
    /// - Parameter siteID: Site for which we'll fetch remote products.
    /// - Parameter query: search term passed in `search` and `search_name_or_sku` request field
    /// - Parameter productTypes: A list of product types to be included in the results.
    /// - Parameter pageNumber: Index of page that should be retrieved.
    ///
    public func searchProductsForPointOfSale(for siteID: Int64,
                                             query: String,
                                             productTypes: [ProductType] = [.simple],
                                             pageNumber: Int = 1) async throws -> PagedItems<POSProduct> {
        var parameters = pointOfSaleProductFetchParameters(
            pageNumber: pageNumber,
            productTypes: productTypes
        )

        parameters.updateValue(query, forKey: ParameterKey.search)

        // Takes precedence over `search` from WC 9.9 to 10.1
        parameters.updateValue(query, forKey: ParameterKey.searchNameOrSKU)

        // Takes precedence over `search_name_or_sku` from WC 10.1+ and is combined with `search` value
        parameters.updateValue([
            ProductSearchField.name.rawValue,
            ProductSearchField.sku.rawValue,
            ProductSearchField.globalUniqueID.rawValue
        ], forKey: ParameterKey.searchFields)

        return try await makePagedPointOfSaleProductsRequest(
            for: siteID,
            pageNumber: pageNumber,
            parameters: parameters)
    }

    /// Fetches a single product or variation by its global unique identifier for Point of Sale.
    /// This method is optimized for barcode scanning, returning only the first matching product.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the product.
    ///     - globalUniqueID: The global unique identifier (e.g. barcode) to search for.
    /// - Returns: A POSProduct if found
    /// - Throws: Error if the product is not found or if there's a network error
    ///
    public func loadPOSProductByGlobalUniqueIdentifier(for siteID: Int64,
                                                       globalUniqueID: String) async throws -> POSProduct {
        let parameters: [String: Any] = [
            ParameterKey.globalUniqueID: globalUniqueID,
            ParameterKey.page: "1",
            ParameterKey.perPage: "1",
            ParameterKey.contextKey: Default.context,
            ParameterKey.fields: POSProduct.requestFields.joined(separator: ","),
            ParameterKey.posProductsOnly: String(true)
        ]

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ListMapper<POSProduct>(siteID: siteID)

        guard let product = try await enqueue(request, mapper: mapper).first else {
            throw NetworkError.notFound()
        }
        return product
    }

    /// Fetches a single product by its ID for Point of Sale.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the product.
    ///     - productID: The ID of the product to fetch.
    /// - Returns: A POSProduct if found
    /// - Throws: Error if the product is not found or if there's a network error
    ///
    public func loadPOSProduct(for siteID: Int64, productID: Int64) async throws -> POSProduct {
        let parameters: [String: Any] = [
            ParameterKey.fields: POSProduct.requestFields.joined(separator: ","),
            ParameterKey.posProductsOnly: String(true)
        ]

        let path = "\(Path.products)/\(productID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = SingleItemMapper<POSProduct>(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
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
    ///
    public func loadProducts(for siteID: Int64,
                             by productIDs: [Int64],
                             pageNumber: Int = Default.pageNumber,
                             pageSize: Int = Default.pageSize) async throws -> [Product] {
        guard productIDs.isEmpty == false else {
            return []
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
        let mapper = ListMapper<Product>(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
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
    ///
    public func searchProducts(for siteID: Int64,
                               keyword: String,
                               searchFields: [ProductSearchField],
                               pageNumber: Int,
                               pageSize: Int,
                               stockStatus: ProductStockStatus? = nil,
                               productStatus: ProductStatus? = nil,
                               productType: ProductType? = nil,
                               productCategory: ProductCategory? = nil,
                               excludedProductIDs: [Int64] = []) async throws -> [Product] {
        let stringOfExcludedProductIDs = excludedProductIDs.map { String($0) }
            .joined(separator: ",")

        let filterParameters = [
            ParameterKey.stockStatus: stockStatus?.rawValue ?? "",
            ParameterKey.productStatus: productStatus?.rawValue ?? "",
            ParameterKey.productType: productType?.rawValue ?? "",
            ParameterKey.category: filterProductCategoryParemeterValue(from: productCategory),
            ParameterKey.exclude: stringOfExcludedProductIDs
            ].filter({ $0.value.isEmpty == false })

        let parameters: [String: Any] = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.search: keyword,
            ParameterKey.searchFields: searchFields.map { $0.rawValue },
            ParameterKey.exclude: stringOfExcludedProductIDs,
            ParameterKey.contextKey: Default.context
        ].merging(filterParameters, uniquingKeysWith: { (first, _) in first })

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ListMapper<Product>(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    /// Retrieves all of the `Product`s that match the SKU. Partial SKU search is supported for WooCommerce version 6.6+, otherwise full SKU match is performed.
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch remote products
    ///   - keyword: Search string that should be matched by the SKU (partial or full depending on the WC version).
    ///   - pageNumber: Number of page that should be retrieved.
    ///   - pageSize: Number of products to be retrieved per page.
    public func searchProductsBySKU(for siteID: Int64,
                                    keyword: String,
                                    pageNumber: Int,
                                    pageSize: Int) async throws -> [Product] {
        let parameters = [
            ParameterKey.sku: keyword,
            ParameterKey.partialSKUSearch: keyword,
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: Default.context
        ]
        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ListMapper<Product>(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    public func searchProductsByGlobalUniqueIdentifier(for siteID: Int64,
                             keyword: String,
                             pageNumber: Int,
                             pageSize: Int) async throws -> [Product] {
        let parameters = [
            ParameterKey.globalUniqueID: keyword,
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: Default.context
        ]
        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ListMapper<Product>(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
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
                               productStatus: ProductStatus? = nil,
                               productType: ProductType? = nil,
                               completion: @escaping (Result<[Int64], Error>) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.fields: ParameterKey.id,
            ParameterKey.productStatus: productStatus?.rawValue ?? "",
            ParameterKey.productType: productType?.rawValue ?? ""
        ].filter({ $0.value.isEmpty == false })

        let path = Path.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ProductIDMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    public func loadNumberOfProducts(siteID: Int64) async throws -> Int64 {
        let path = Path.productsTotal
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, availableAsRESTRequest: true)
        let mapper = ProductsTotalMapper()
        return try await enqueue(request, mapper: mapper)
    }

    public func loadStock(for siteID: Int64,
                          with stockType: String,
                          pageNumber: Int,
                          pageSize: Int,
                          order: ProductsRemote.Order) async throws -> [ProductStock] {
        let path = Path.stockReports
        let parameters: [String: Any] = [
            ParameterKey.type: stockType,
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.order: order.value
        ]
        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductStockListMapper(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    public func loadProductReports(for siteID: Int64,
                                   productIDs: [Int64],
                                   timeZone: TimeZone,
                                   earliestDateToInclude: Date,
                                   latestDateToInclude: Date,
                                   pageSize: Int,
                                   pageNumber: Int,
                                   orderBy: ProductsRemote.OrderKey,
                                   order: ProductsRemote.Order) async throws -> [ProductReport] {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        dateFormatter.timeZone = timeZone
        let path = Path.productReports
        let parameters: [String: Any] = [
            ParameterKey.products: productIDs,
            ParameterKey.after: dateFormatter.string(from: earliestDateToInclude),
            ParameterKey.before: dateFormatter.string(from: latestDateToInclude),
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.order: order.value,
            ParameterKey.orderBy: orderBy.value,
            ParameterKey.extendedInfo: true
        ]
        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductReportListMapper()
        return try await enqueue(request, mapper: mapper)
    }

    public func loadVariationReports(for siteID: Int64,
                                     productIDs: [Int64],
                                     variationIDs: [Int64],
                                     timeZone: TimeZone,
                                     earliestDateToInclude: Date,
                                     latestDateToInclude: Date,
                                     pageSize: Int,
                                     pageNumber: Int,
                                     orderBy: ProductsRemote.OrderKey,
                                     order: ProductsRemote.Order) async throws -> [ProductReport] {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        dateFormatter.timeZone = timeZone
        let path = Path.variationReports
        let parameters: [String: Any] = [
            ParameterKey.products: productIDs,
            ParameterKey.variations: variationIDs,
            ParameterKey.after: dateFormatter.string(from: earliestDateToInclude),
            ParameterKey.before: dateFormatter.string(from: latestDateToInclude),
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.order: order.value,
            ParameterKey.orderBy: orderBy.value,
            ParameterKey.extendedInfo: true
        ]
        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductReportListMapper()
        return try await enqueue(request, mapper: mapper)
    }
}


// MARK: - Constants
//
public extension ProductsRemote {
    enum OrderKey {
        case date
        case name
        case popularity
        // available for use in `GET wc-analytics/reports/products/stats` only.
        case itemsSold
    }

    enum Order {
        case ascending
        case descending
    }

    enum Default {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = Remote.Default.firstPageNumber
        public static let context: String = "edit"
    }

    private enum Path {
        static let products   = "products"
        static let productsTotal = "reports/products/totals"
        static let stockReports = "reports/stock"
        static let productReports = "reports/products"
        static let variationReports = "reports/variations"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
        static let exclude: String    = "exclude"
        static let include: String    = "include"
        static let search: String     = "search"
        static let searchNameOrSKU: String = "search_name_or_sku"
        static let searchFields: String = "search_fields"
        static let orderBy: String    = "orderby"
        static let order: String      = "order"
        static let sku: String        = "sku"
        static let partialSKUSearch: String = "search_sku"
        static let globalUniqueID: String = "global_unique_id"
        static let productStatus: String = "status"
        static let productType: String = "type"
        static let productTypes: String = "include_types"
        static let stockStatus: String = "stock_status"
        static let category: String   = "category"
        static let fields: String     = "_fields"
        static let images: String = "images"
        static let id: String         = "id"
        static let type = "type"
        static let products = "products"
        static let variations = "variations"
        static let before = "before"
        static let after = "after"
        static let extendedInfo = "extended_info"
        static let downloadable = "downloadable"
        static let posProductsOnly = "pos_products_only"
    }

    private enum ParameterValues {
        static let skuFieldValues: String = "sku"
        static let productSegment = "product"
        static let itemsSold = "items_sold"
    }
}

public enum ProductSearchField: String {
    case name
    case sku
    case globalUniqueID = "global_unique_id"
}

private extension ProductsRemote {
    enum POSConstants {
        static let productsPerPage = "25"
        static let productType = "simple"
        static let productStatus = "publish"
    }
}

private extension ProductsRemote {
    /// Returns the category Id in string format, or empty string if the product category is nil
    ///
    func filterProductCategoryParemeterValue(from productCategory: ProductCategory?) -> String {
        guard let productCategory else {
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
        case .itemsSold:
            return "items_sold"
        case .popularity:
            return "popularity"
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
