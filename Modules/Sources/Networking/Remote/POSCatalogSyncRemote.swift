import Foundation

/// Protocol for POS Catalog Sync Remote operations.
public protocol POSCatalogSyncRemoteProtocol {
    /// Loads POS products modified after the specified date for incremental sync.
    ///
    /// - Parameters:
    ///   - modifiedAfter: Only products modified after this date will be returned.
    ///   - siteID: Site ID to load products from.
    ///   - pageNumber: Page number for pagination.
    /// - Returns: Paginated list of POS products.
    // TODO - remove the periphery ignore comment when the incremental sync is integrated with POS.
    // periphery:ignore
    func loadProducts(modifiedAfter: Date, siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProduct>

    /// Loads POS product variations modified after the specified date for incremental sync.
    ///
    /// - Parameters:
    ///   - modifiedAfter: Only variations modified after this date will be returned.
    ///   - siteID: Site ID to load variations from.
    ///   - pageNumber: Page number for pagination.
    /// - Returns: Paginated list of POS product variations.
    // TODO - remove the periphery ignore comment when the incremental sync is integrated with POS.
    // periphery:ignore
    func loadProductVariations(modifiedAfter: Date, siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation>

    /// Starts generation of a POS catalog.
    /// The catalog is generated asynchronously and a download URL may be returned when the file is ready.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to generate catalog for.
    /// - Returns: Catalog job response with job ID.
    ///
    // periphery:ignore - TODO - remove this periphery ignore comment when this endpoint is integrated with catalog sync
    func requestCatalogGeneration(for siteID: Int64) async throws -> POSCatalogRequestResponse

    /// Downloads the generated catalog at the specified download URL.
    /// - Parameters:
    ///   - siteID: Site ID to download catalog for.
    ///   - downloadURL: Download URL of the catalog file.
    /// - Returns: List of products and variations in the POS catalog.
    // periphery:ignore - TODO - remove this periphery ignore comment when this method is integrated with catalog sync
    func downloadCatalog(for siteID: Int64, downloadURL: String) async throws -> POSCatalogResponse

    /// Loads POS products for full sync.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to load products from.
    ///   - pageNumber: Page number for pagination.
    /// - Returns: Paginated list of POS products.
    func loadProducts(siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProduct>

    /// Loads POS product variations for full sync.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to load variations from.
    ///   - pageNumber: Page number for pagination.
    /// - Returns: Paginated list of POS product variations.
    func loadProductVariations(siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation>

    /// Gets the total count of products for the specified site.
    ///
    /// - Parameter siteID: Site ID to get product count for.
    /// - Returns: Total number of products.
    func getProductCount(siteID: Int64) async throws -> Int

    /// Gets the total count of product variations for the specified site.
    ///
    /// - Parameter siteID: Site ID to get variation count for.
    /// - Returns: Total number of variations.
    func getProductVariationCount(siteID: Int64) async throws -> Int
}

/// POS Catalog Sync: Remote Endpoints
///
public class POSCatalogSyncRemote: Remote, POSCatalogSyncRemoteProtocol {
    private let dateFormatter = ISO8601DateFormatter()

    // MARK: - Incremental Sync Endpoints

    /// Loads POS products modified after the specified date.
    ///
    /// - Parameters:
    ///   - modifiedAfter: Only products modified after this date will be returned.
    ///   - siteID: Site ID to load products from.
    ///   - pageNumber: Page number for pagination.
    /// - Returns: Paginated list of POS products.
    ///
    // periphery:ignore - TODO - remove this periphery ignore comment when this endpoint is integrated with catalog sync
    public func loadProducts(modifiedAfter: Date, siteID: Int64, pageNumber: Int)
    async throws -> PagedItems<POSProduct> {
        let path = Path.products
        let parameters = [
            ParameterKey.modifiedAfter: dateFormatter.string(from: modifiedAfter),
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProduct.requestFields.joined(separator: ",")
        ]

        let request = JetpackRequest(
            wooApiVersion: .mark3,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )
        let mapper = ListMapper<POSProduct>(siteID: siteID)
        let (products, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)

        return createPagedItems(items: products, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }

    /// Loads POS product variations modified after the specified date.
    ///
    /// - Parameters:
    ///   - modifiedAfter: Only variations modified after this date will be returned.
    ///   - siteID: Site ID to load variations from.
    ///   - pageNumber: Page number for pagination.
    /// - Returns: Paginated list of POS product variations.
    ///
    // periphery:ignore - TODO - remove this periphery ignore comment when this endpoint is integrated with catalog sync
    public func loadProductVariations(modifiedAfter: Date, siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        let path = Path.variations
        let parameters = [
            ParameterKey.modifiedAfter: dateFormatter.string(from: modifiedAfter),
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProductVariation.requestFields.joined(separator: ",")
        ]

        let request = JetpackRequest(
            wooApiVersion: .wcAnalytics,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )
        let mapper = ListMapper<POSProductVariation>(siteID: siteID)
        let (variations, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)

        return createPagedItems(items: variations, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }

    // MARK: - Full Sync Endpoints

    /// Starts generation of a POS catalog.
    /// The catalog is generated asynchronously and a download URL may be returned immediately or via the status response endpoint associated with a job ID.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to generate catalog for.
    /// - Returns: Catalog job response with job ID.
    ///
    // periphery:ignore - TODO - remove this periphery ignore comment when this endpoint is integrated with catalog sync
    public func requestCatalogGeneration(for siteID: Int64) async throws -> POSCatalogRequestResponse {
        let path = "products/catalog"
        let parameters: [String: Any] = [
            ParameterKey.fullSyncFields: POSProduct.requestFields,
            // TODO: make it a parameter
            "force_generate": true
        ]
        let request = JetpackRequest(
            wooApiVersion: .mark3,
            method: .post,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )
        let mapper = SingleItemMapper<POSCatalogRequestResponse>(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    /// Downloads the generated catalog at the specified download URL.
    /// - Parameters:
    ///   - siteID: Site ID to download catalog for.
    ///   - downloadURL: Download URL of the catalog file.
    /// - Returns: List of products and variations in the POS catalog.
    // periphery:ignore - TODO - remove this periphery ignore comment when this method is integrated with catalog sync
    public func downloadCatalog(for siteID: Int64, downloadURL: String) async throws -> POSCatalogResponse {
        // TODO: WOOMOB-1173 - move download task to the background using `URLSessionConfiguration.background`
        guard let url = URL(string: downloadURL) else {
            throw NetworkError.invalidURL
        }
        let request = URLRequest(url: url)
        let mapper = ListMapper<POSProduct>(siteID: siteID)
        let items = try await enqueue(request, mapper: mapper)
        let variationProductTypeKey = "variation"
        let products = items.filter { $0.productTypeKey != variationProductTypeKey }
        let variations = items.filter { $0.productTypeKey == variationProductTypeKey }
            .map { $0.toVariation }
        return POSCatalogResponse(products: products, variations: variations)
    }

    /// Loads POS products for full sync.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to load products from.
    ///   - pageNumber: Page number for pagination.
    /// - Returns: Paginated list of POS products.
    ///
    // periphery:ignore - TODO - remove this periphery ignore comment when this endpoint is integrated with catalog sync
    public func loadProducts(siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let path = Path.products
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProduct.requestFields.joined(separator: ",")
        ]

        let request = JetpackRequest(
            wooApiVersion: .mark3,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )
        let mapper = ListMapper<POSProduct>(siteID: siteID)
        let (products, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)

        return createPagedItems(items: products, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }

    /// Loads POS product variations for full sync.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to load variations from.
    ///   - pageNumber: Page number for pagination.
    /// - Returns: Paginated list of POS product variations.
    ///
    // periphery:ignore - TODO - remove this periphery ignore comment when this endpoint is integrated with catalog sync
    public func loadProductVariations(siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        let path = Path.variations
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProductVariation.requestFields.joined(separator: ",")
        ]

        let request = JetpackRequest(
            wooApiVersion: .wcAnalytics,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )
        let mapper = ListMapper<POSProductVariation>(siteID: siteID)
        let (variations, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)

        return createPagedItems(items: variations, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }

    // MARK: - Count Endpoints

    /// Gets the total count of products for the specified site.
    ///
    /// - Parameter siteID: Site ID to get product count for.
    /// - Returns: Total number of products.
    public func getProductCount(siteID: Int64) async throws -> Int {
        let path = Path.products
        let parameters = [
            ParameterKey.page: String(1),
            ParameterKey.perPage: String(1),
            ParameterKey.fields: POSProductVariation.requestFields.first ?? ""
        ]

        let request = JetpackRequest(
            wooApiVersion: .mark3,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )
        let responseHeaders = try await enqueueWithResponseHeaders(request)

        return totalItemsCount(from: responseHeaders) ?? 0
    }

    /// Gets the total count of product variations for the specified site.
    ///
    /// - Parameter siteID: Site ID to get variation count for.
    /// - Returns: Total number of variations.
    public func getProductVariationCount(siteID: Int64) async throws -> Int {
        let path = Path.variations
        let parameters = [
            ParameterKey.page: String(1),
            ParameterKey.perPage: String(1),
            ParameterKey.fields: POSProductVariation.requestFields.first ?? ""
        ]

        let request = JetpackRequest(
            wooApiVersion: .wcAnalytics,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )
        let responseHeaders = try await enqueueWithResponseHeaders(request)

        return totalItemsCount(from: responseHeaders) ?? 0
    }
}

// MARK: - Constants
//
private extension POSCatalogSyncRemote {
    enum Constants {
        static let defaultPageSize = 100
    }

    enum ParameterKey {
        static let modifiedAfter = "modified_after"
        static let page = "page"
        static let perPage = "per_page"
        static let fields = "_fields"
        static let fullSyncFields = "fields"
    }

    enum Path {
        static let products = "products"
        static let variations = "variations"
    }
}

// MARK: - Response Models

/// Response from catalog generation request.
// periphery:ignore - TODO - remove this periphery ignore comment when the corresponding endpoint is integrated with catalog sync
public struct POSCatalogRequestResponse: Decodable {
    /// Current status of the catalog generation job.
    public let status: POSCatalogStatus
    /// Download URL when it is already available.
    public let downloadURL: String?

    private enum CodingKeys: String, CodingKey {
        case status
        case downloadURL = "download_url"
    }
}

/// Catalog generation status.
public enum POSCatalogStatus: String, Decodable {
    case pending
    case processing
    case complete
    case failed
}

/// POS catalog from download.
// periphery:ignore - TODO - remove this periphery ignore comment when the corresponding endpoint is integrated with catalog sync
public struct POSCatalogResponse {
    public let products: [POSProduct]
    public let variations: [POSProductVariation]
}

private extension POSProduct {
    var toVariation: POSProductVariation {
        let variationAttributes = attributes.compactMap { attribute in
            try? attribute.toProductVariationAttribute()
        }

        let firstImage = images.first

        return .init(
            siteID: siteID,
            productID: parentID,
            productVariationID: productID,
            attributes: variationAttributes,
            image: firstImage,
            fullDescription: fullDescription,
            sku: sku,
            globalUniqueID: globalUniqueID,
            price: price,
            downloadable: downloadable,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatusKey: stockStatusKey
        )
    }
}
