import Foundation

/// Remote API client for Point of Sale catalog operations
/// Handles async catalog generation, status checking, and download
///
public final class POSCatalogRemote: Remote {

    // MARK: - API Endpoints

    /// Initiates catalog generation and returns job ID
    /// - Parameters:
    ///   - fields: Optional list of fields to include in catalog export. Defaults to all fields if not specified
    ///   - forceGenerate: Optional flag to force regeneration even if cached catalog exists. Defaults to false
    /// - Returns: Job ID for tracking catalog generation progress
    public func generateCatalog(for siteID: Int64, fields: [String]? = nil, forceGenerate: Bool = false) async throws -> CatalogJobResponse {
        let path = "catalog"
        let parameters = buildGenerateParameters(fields: fields, forceGenerate: forceGenerate)

        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = SingleItemMapper<CatalogJobResponse>(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    /// Checks the status of a catalog generation job
    /// - Parameter jobID: Job ID returned from generateCatalog
    /// - Returns: Status information including completion status and download URL when ready
    public func checkCatalogStatus(for siteID: Int64, jobID: String) async throws -> CatalogStatusResponse {
        let path = "catalog/status/\(jobID)"

        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, availableAsRESTRequest: true)
        let mapper = SingleItemMapper<CatalogStatusResponse>(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    /// Downloads the generated catalog file
    /// - Parameter filename: Catalog filename from status response
    /// - Returns: Raw catalog data
//    public func downloadCatalog(for siteID: Int64, filename: String) async throws -> Data {
//        let path = "catalog/download"
//        let parameters = ["filename": filename]
//
//        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
//
//        return try await enqueueRawData(request)
//    }

    // MARK: - Private Helpers

    private func buildGenerateParameters(fields: [String]?, forceGenerate: Bool) -> [String: Any] {
        var parameters: [String: Any] = [:]

         if let fields = fields {
             parameters["fields"] = fields
         }

        // if forceGenerate {
        //     parameters["force_generate"] = forceGenerate
        // }

        return parameters
    }
}

// MARK: - Response Models

/// Response from catalog generation request
public struct CatalogJobResponse: Decodable {
    /// Unique identifier for tracking the catalog generation job
    public let jobID: String

    private enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
    }
}

/// Response from catalog status check
public struct CatalogStatusResponse: Decodable {
    /// Current status of the catalog generation job
    public let status: CatalogStatus
    /// Download URL for the completed catalog (available when status is complete)
    public let downloadURL: String?
    /// Filename of the generated catalog
    public let filename: String

    private enum CodingKeys: String, CodingKey {
        case status
        case downloadURL = "download_url"
        case filename
    }
}

/// Catalog generation status
public enum CatalogStatus: String, Decodable {
    case pending
    case processing
    case complete
}

// MARK: - Response Mappers

/// Mapper for catalog job generation response
private struct CatalogJobMapper: Mapper {
    func map(response: Data) throws -> CatalogJobResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(CatalogJobResponse.self, from: response)
    }
}

/// Mapper for catalog status response
private struct CatalogStatusMapper: Mapper {
    func map(response: Data) throws -> CatalogStatusResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(CatalogStatusResponse.self, from: response)
    }
}
