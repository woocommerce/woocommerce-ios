import Foundation

/// POS Catalog Sync: Remote Endpoints
///
public class POSCatalogSyncRemote: Remote {
    private let dateFormatter = ISO8601DateFormatter()

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
        let path = "products"
        let parameters = [
            ParameterKey.modifiedAfter: dateFormatter.string(from: modifiedAfter),
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProduct.requestFields.joined(separator: ",")
        ]

        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
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
        let path = "variations"
        let parameters = [
            ParameterKey.modifiedAfter: dateFormatter.string(from: modifiedAfter),
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(Constants.defaultPageSize),
            ParameterKey.fields: POSProductVariation.requestFields.joined(separator: ",")
        ]

        let request = JetpackRequest(wooApiVersion: .wcAnalytics, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ListMapper<POSProductVariation>(siteID: siteID)
        let (variations, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)

        return createPagedItems(items: variations, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }

    /// Generates a POS catalog. The catalog is generated asynchronously and a download URL is returned in the
    /// status response endpoint associated with a job ID.
    ///
    /// - Parameters:
    ///   - siteID: Site ID to generate catalog for.
    ///   - fields: Optional array of fields to include in catalog.
    ///   - forceGenerate: Whether to force generation of a new catalog.
    /// - Returns: Catalog job response with job ID.
    ///
    // periphery:ignore - TODO - remove this periphery ignore comment when this endpoint is integrated with catalog sync
    public func generateCatalog(for siteID: Int64, forceGenerate: Bool = false) async throws -> POSCatalogGenerationResponse {
        let path = "catalog"
        let parameters: [String: Any] = [
            ParameterKey.fullSyncFields: POSProduct.requestFields
        ]

        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = SingleItemMapper<POSCatalogGenerationResponse>(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    /// Checks the status of a catalog generation job. A download URL is returned when the job is complete.
    ///
    /// - Parameters:
    ///   - siteID: Site ID for the catalog job.
    ///   - jobID: Job ID to check status for.
    /// - Returns: Catalog status response.
    ///
    // periphery:ignore - TODO - remove this periphery ignore comment when this endpoint is integrated with catalog sync
    public func checkCatalogStatus(for siteID: Int64, jobID: String) async throws -> POSCatalogStatusResponse {
        let path = "catalog/status/\(jobID)"

        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, availableAsRESTRequest: true)
        let mapper = SingleItemMapper<POSCatalogStatusResponse>(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    /// Downloads the generated catalog at the specified download URL.
    /// - Parameters:
    ///   - siteID: Site ID to download catalog for.
    ///   - downloadURL: Download URL of the catalog file.
    /// - Returns: List of products and variations in the POS catalog.
    public func downloadCatalog(for siteID: Int64, downloadURL: String) async throws -> POSCatalog {
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
        return POSCatalog(products: products, variations: variations)
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
}

// MARK: - Response Models

/// Response from catalog generation request.
// periphery:ignore - TODO - remove this periphery ignore comment when the corresponding endpoint is integrated with catalog sync
public struct POSCatalogGenerationResponse: Decodable {
    /// Unique identifier for tracking the catalog generation job.
    public let jobID: String

    private enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
    }
}

/// Response from catalog status check.
// periphery:ignore - TODO - remove this periphery ignore comment when the corresponding endpoint is integrated with catalog sync
public struct POSCatalogStatusResponse: Decodable {
    /// Current status of the catalog generation job.
    public let status: POSCatalogStatus
    /// Download URL for the completed catalog (available when status is complete).
    public let downloadURL: String?
    /// Progress percentage of the catalog generation (0.0 to 100.0).
    public let progress: Double

    private enum CodingKeys: String, CodingKey {
        case status
        case downloadURL = "download_url"
        case progress
    }
}

/// Catalog generation status.
public enum POSCatalogStatus: String, Decodable {
    case pending
    case processing
    case complete
}

/// POS catalog from download.
// periphery:ignore - TODO - remove this periphery ignore comment when the corresponding endpoint is integrated with catalog sync
public struct POSCatalog {
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
            sku: sku,
            globalUniqueID: globalUniqueID,
            price: price,
            regularPrice: regularPrice,
            salePrice: salePrice,
            onSale: onSale,
            downloadable: downloadable,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatusKey: stockStatusKey
        )
    }
}
