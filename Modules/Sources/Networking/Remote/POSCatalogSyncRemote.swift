// periphery:ignore:all
import Foundation

/// Protocol for POS Catalog Sync Remote operations.
public protocol POSCatalogSyncRemoteProtocol {
    /// Loads POS products modified after the specified date for incremental sync.
    ///
    /// - Parameters:
    ///   - modifiedAfter: Only products modified after this date will be returned.
    ///   - siteID: Site ID to load products from.
    ///   - pageNumber: Page number for pagination.
    ///   - includeStatus: Optional status to include (e.g., "trash" to fetch trashed products).
    ///   - posProductsOnly: Whether to filter to POS-eligible products only.
    /// - Returns: Paginated list of POS products.
    // TODO - remove the periphery ignore comment when the incremental sync is integrated with POS.
    // periphery:ignore
    func loadProducts(modifiedAfter: Date, siteID: Int64, pageNumber: Int, includeStatus: String?, posProductsOnly: Bool) async throws -> PagedItems<POSProduct>

    /// Loads POS product variations modified after the specified date for incremental sync.
    ///
    /// - Parameters:
    ///   - modifiedAfter: Only variations modified after this date will be returned.
    ///   - siteID: Site ID to load variations from.
    ///   - pageNumber: Page number for pagination.
    ///   - posProductsOnly: Whether to filter to POS-eligible variations only.
    /// - Returns: Paginated list of POS product variations.
    // TODO - remove the periphery ignore comment when the incremental sync is integrated with POS.
    // periphery:ignore
    func loadProductVariations(modifiedAfter: Date, siteID: Int64, pageNumber: Int, posProductsOnly: Bool) async throws -> PagedItems<POSProductVariation>

    /// Starts generation of a POS catalog.
    /// The catalog is generated asynchronously and a download URL may be returned when the file is ready.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to generate catalog for.
    ///   - forceGeneration: Whether to always generate a catalog.
    ///   - allowCellular: Should cellular data be used if required.
    /// - Returns: Catalog job response with job ID.
    ///
    // periphery:ignore - TODO - remove this periphery ignore comment when this endpoint is integrated with catalog sync
    func requestCatalogGeneration(for siteID: Int64, forceGeneration: Bool, allowCellular: Bool) async throws -> POSCatalogRequestResponse

    /// Downloads the generated catalog at the specified download URL.
    /// - Parameters:
    ///   - siteID: Site ID to download catalog for.
    ///   - downloadURL: Download URL of the catalog file.
    ///   - allowCellular: Should cellular data be used if required.
    /// - Returns: List of products and variations in the POS catalog.
    func downloadCatalog(for siteID: Int64,
                         downloadURL: String,
                         allowCellular: Bool) async throws -> POSCatalogResponse

    /// Parses a downloaded catalog file.
    /// Used for processing background downloads after app wake.
    /// - Parameters:
    ///   - fileURL: Local file URL of the downloaded catalog.
    ///   - siteID: Site ID for proper mapping.
    /// - Returns: Parsed POS catalog response.
    func parseDownloadedCatalog(from fileURL: URL, siteID: Int64) async throws -> POSCatalogResponse

    /// Loads POS products for full sync.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to load products from.
    ///   - pageNumber: Page number for pagination.
    ///   - allowCellular: Should cellular data be used if required.
    ///   - posProductsOnly: Whether to filter to POS-eligible products only.
    /// - Returns: Paginated list of POS products.
    func loadProducts(siteID: Int64, pageNumber: Int, allowCellular: Bool, posProductsOnly: Bool) async throws -> PagedItems<POSProduct>

    /// Loads POS product variations for full sync.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to load variations from.
    ///   - pageNumber: Page number for pagination.
    ///   - allowCellular: Should cellular data be used if required.
    ///   - posProductsOnly: Whether to filter to POS-eligible variations only.
    /// - Returns: Paginated list of POS product variations.
    func loadProductVariations(siteID: Int64, pageNumber: Int, allowCellular: Bool, posProductsOnly: Bool) async throws -> PagedItems<POSProductVariation>

    /// Gets the total count of products for the specified site.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to get product count for.
    ///   - posProductsOnly: Whether to filter to POS-eligible products only.
    /// - Returns: Total number of products.
    func getProductCount(siteID: Int64, posProductsOnly: Bool) async throws -> Int

    /// Gets the total count of product variations for the specified site.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to get variation count for.
    ///   - posProductsOnly: Whether to filter to POS-eligible variations only.
    /// - Returns: Total number of variations.
    func getProductVariationCount(siteID: Int64, posProductsOnly: Bool) async throws -> Int
}

/// POS Catalog Sync: Remote Endpoints
///
public class POSCatalogSyncRemote: Remote, POSCatalogSyncRemoteProtocol {
    private let dateFormatter = ISO8601DateFormatter()
    private let backgroundDownloader: BackgroundDownloadProtocol
    private let fileManager: FileManager

    public init(network: Network,
                backgroundDownloader: BackgroundDownloadProtocol = BackgroundDownloadService(),
                fileManager: FileManager = .default) {
        self.backgroundDownloader = backgroundDownloader
        self.fileManager = fileManager
        super.init(network: network)
    }

    // MARK: - Incremental Sync Endpoints

    /// Loads POS products modified after the specified date.
    ///
    /// - Parameters:
    ///   - modifiedAfter: Only products modified after this date will be returned.
    ///   - siteID: Site ID to load products from.
    ///   - pageNumber: Page number for pagination.
    ///   - includeStatus: Optional status to include (e.g., "trash" to fetch trashed products).
    ///   - posProductsOnly: Whether to filter to POS-eligible products only.
    /// - Returns: Paginated list of POS products.
    ///
    public func loadProducts(modifiedAfter: Date,
                             siteID: Int64,
                             pageNumber: Int,
                             includeStatus: String? = nil,
                             posProductsOnly: Bool = false)
    async throws -> PagedItems<POSProduct> {
        let path = Path.products
        var parameters: [String: String] = [
            ParameterKey.modifiedAfter: dateFormatter.string(from: modifiedAfter),
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProduct.requestFields.joined(separator: ","),
            ParameterKey.posProductsOnly: String(posProductsOnly)
        ]

        if let includeStatus = includeStatus {
            parameters[ParameterKey.includeStatus] = includeStatus
        }

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
    ///   - posProductsOnly: Whether to filter to POS-eligible variations only.
    /// - Returns: Paginated list of POS product variations.
    ///
    public func loadProductVariations(modifiedAfter: Date,
                                      siteID: Int64,
                                      pageNumber: Int,
                                      posProductsOnly: Bool = false) async throws -> PagedItems<POSProductVariation> {
        let path = Path.variations
        let parameters = [
            ParameterKey.modifiedAfter: dateFormatter.string(from: modifiedAfter),
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProductVariation.requestFields.joined(separator: ","),
            ParameterKey.posProductsOnly: String(posProductsOnly)
        ]

        let request = JetpackRequest(
            wooApiVersion: .mark3,
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
    ///   - forceGeneration: Whether to always generate a catalog.
    ///   - allowCellular: Should cellular data be used if required.
    /// - Returns: Catalog job response with job ID.
    ///
    public func requestCatalogGeneration(for siteID: Int64, forceGeneration: Bool, allowCellular: Bool) async throws -> POSCatalogRequestResponse {
        let path = "catalog/create"
        var parameters: [String: Any] = [
            ParameterKey.catalogProductFields: POSProduct.requestFields,
            ParameterKey.catalogVariationFields: POSProductVariation.requestFields
        ]
        if forceGeneration {
            parameters[ParameterKey.force] = true
        }
        let request = JetpackRequest(
            wooApiVersion: .wcPosV1,
            method: .post,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true,
            allowsCellularAccess: allowCellular
        )
        let mapper = SingleItemMapper<POSCatalogRequestResponse>(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    /// Downloads the generated catalog at the specified download URL using background downloads.
    /// - Parameters:
    ///   - siteID: Site ID to download catalog for.
    ///   - downloadURL: Download URL of the catalog file.
    ///   - allowCellular: Should cellular data be used if required.
    /// - Returns: List of products and variations in the POS catalog.
    /// - Note: Uses background download with URLSessionConfiguration.background to support app suspension.
    public func downloadCatalog(for siteID: Int64,
                                downloadURL: String,
                                allowCellular: Bool) async throws -> POSCatalogResponse {
        guard let url = URL(string: downloadURL) else {
            throw NetworkError.invalidURL
        }

        let sessionIdentifier = "\(POSCatalogSyncConstants.backgroundDownloadSessionPrefix).\(siteID).\(UUID().uuidString)"

        // Save download state so we can resume if app is terminated
        let downloadState = BackgroundDownloadState(
            sessionIdentifier: sessionIdentifier,
            siteID: siteID
        )
        BackgroundDownloadState.save(downloadState)

        let fileURL = try await backgroundDownloader.downloadFile(from: url,
                                                                   sessionIdentifier: sessionIdentifier,
                                                                   allowCellular: allowCellular)

        // Download completed - parse the file
        let catalogResponse = try await parseDownloadedCatalog(from: fileURL, siteID: siteID)

        // Clear the saved state since we successfully completed
        BackgroundDownloadState.clear()

        return catalogResponse
    }

    /// Parses the downloaded catalog file.
    /// - Parameters:
    ///   - fileURL: Local file URL of the downloaded catalog.
    ///   - siteID: Site ID for proper mapping.
    /// - Returns: Parsed POS catalog.
    public func parseDownloadedCatalog(from fileURL: URL, siteID: Int64) async throws -> POSCatalogResponse {
        let data = try Data(contentsOf: fileURL)

        // Clean up downloaded files, but only if they're in our Documents directory.
        // Files in iOS temporary directories should be left for iOS to clean up automatically.
        defer {
            cleanupDownloadedFileIfNeeded(at: fileURL)
        }

        let mapper = ListMapper<POSCatalogItem>(siteID: siteID)
        let items = try mapper.map(response: data)

        var products: [POSProduct] = []
        var variations: [POSProductVariation] = []

        for item in items {
            switch item {
            case .product(let product):
                products.append(product)
            case .variation(let variation):
                variations.append(variation)
            }
        }

        return POSCatalogResponse(products: products, variations: variations)
    }

    /// Cleans up the downloaded catalog file if it's in our Documents directory.
    /// Files in temporary directories are left for iOS to clean up automatically.
    private func cleanupDownloadedFileIfNeeded(at fileURL: URL) {
        // Only clean up files in our Documents directory
        // Temporary files should be left for iOS to handle
        let documentsURLs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsURL = documentsURLs.first,
              fileURL.path.hasPrefix(documentsURL.path),
              fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        try? fileManager.removeItem(at: fileURL)
    }

    /// Loads POS products for full sync.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to load products from.
    ///   - pageNumber: Page number for pagination.
    ///   - allowCellular: Should cellular data be used if required.
    ///   - posProductsOnly: Whether to filter to POS-eligible products only.
    /// - Returns: Paginated list of POS products.
    ///
    public func loadProducts(siteID: Int64,
                             pageNumber: Int,
                             allowCellular: Bool,
                             posProductsOnly: Bool = false) async throws -> PagedItems<POSProduct> {
        let path = Path.products
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProduct.requestFields.joined(separator: ","),
            ParameterKey.posProductsOnly: String(posProductsOnly)
        ]

        let request = JetpackRequest(
            wooApiVersion: .mark3,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true,
            allowsCellularAccess: allowCellular
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
    ///   - allowCellular: Should cellular data be used if required.
    ///   - posProductsOnly: Whether to filter to POS-eligible variations only.
    /// - Returns: Paginated list of POS product variations.
    ///
    public func loadProductVariations(siteID: Int64,
                                      pageNumber: Int,
                                      allowCellular: Bool,
                                      posProductsOnly: Bool = false) async throws -> PagedItems<POSProductVariation> {
        let path = Path.variations
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProductVariation.requestFields.joined(separator: ","),
            ParameterKey.posProductsOnly: String(posProductsOnly)
        ]

        let request = JetpackRequest(
            wooApiVersion: .mark3,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true,
            allowsCellularAccess: allowCellular
        )
        let mapper = ListMapper<POSProductVariation>(siteID: siteID)
        let (variations, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)

        return createPagedItems(items: variations, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }

    // MARK: - Count Endpoints

    /// Gets the total count of products for the specified site.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to get product count for.
    ///   - posProductsOnly: Whether to filter to POS-eligible products only.
    /// - Returns: Total number of products.
    public func getProductCount(siteID: Int64, posProductsOnly: Bool = false) async throws -> Int {
        let path = Path.products
        let parameters = [
            ParameterKey.page: String(1),
            ParameterKey.perPage: String(1),
            ParameterKey.fields: POSProductVariation.requestFields.first ?? "",
            ParameterKey.posProductsOnly: String(posProductsOnly)
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
    /// - Parameters:
    ///   - siteID: Site ID to get variation count for.
    ///   - posProductsOnly: Whether to filter to POS-eligible variations only.
    /// - Returns: Total number of variations.
    public func getProductVariationCount(siteID: Int64, posProductsOnly: Bool = false) async throws -> Int {
        let path = Path.variations
        let parameters = [
            ParameterKey.page: String(1),
            ParameterKey.perPage: String(1),
            ParameterKey.fields: POSProductVariation.requestFields.first ?? "",
            ParameterKey.posProductsOnly: String(posProductsOnly)
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
        static let catalogProductFields = "_product_fields"
        static let catalogVariationFields = "_variation_fields"
        static let force = "force"
        static let includeStatus = "include_status"
        static let posProductsOnly = "pos_products_only"
    }

    enum Path {
        static let products = "products"
        static let variations = "variations"
    }
}

// MARK: - Response Models

/// Response from catalog generation request.
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

/// Represents a single item in the POS catalog download response.
/// Decodes the type-tagged wrapper and directly parses the nested data in a single pass.
public enum POSCatalogItem: Decodable {
    case product(POSProduct)
    case variation(POSProductVariation)

    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "variation":
            self = .variation(try container.decode(POSProductVariation.self, forKey: .data))
        default:
            self = .product(try container.decode(POSProduct.self, forKey: .data))
        }
    }
}

/// POS catalog from download.
public struct POSCatalogResponse {
    public let products: [POSProduct]
    public let variations: [POSProductVariation]
}

// MARK: - POS Catalog Sync Constants

/// Constants used across POS catalog sync functionality
public enum POSCatalogSyncConstants {
    /// Background download session identifier prefix for POS catalog downloads
    public static let backgroundDownloadSessionPrefix = "com.woocommerce.pos.catalog.download"
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
