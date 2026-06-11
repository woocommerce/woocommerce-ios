import Foundation

/// Errors specific to the file-based POS catalog API.
public enum POSCatalogFileError: Error {
    case downloadFailed(statusCode: Int, contentType: String?)
    /// The host blocks direct access to the generated catalog file (e.g. an Apache `.htaccess` returning 403,
    /// or an HTML error page served instead of the catalog JSON).
    /// Status code and content type are nil when the block is detected from the file body alone
    /// (background downloads don't retain response metadata).
    case blocked(statusCode: Int?, contentType: String?)
    case invalidResponse(statusCode: Int?, contentType: String?, underlyingError: Error)
}

extension POSCatalogFileError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let statusCode, _):
            return "Catalog file download failed with HTTP status \(statusCode)"
        case .blocked(let statusCode, _):
            return "Catalog file access blocked by the host (HTTP status \(statusCode.map(String.init) ?? "unknown"))"
        case .invalidResponse:
            return "Catalog file response could not be parsed"
        }
    }
}
