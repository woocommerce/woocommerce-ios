import Foundation

/// Errors specific to the file-based POS catalog API.
public enum POSCatalogFileError: Error {
    case downloadFailed(statusCode: Int, contentType: String?)
    case invalidResponse(statusCode: Int?, contentType: String?, underlyingError: Error)
}

extension POSCatalogFileError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let statusCode, _):
            return "Catalog file download failed with HTTP status \(statusCode)"
        case .invalidResponse:
            return "Catalog file response could not be parsed"
        }
    }
}
