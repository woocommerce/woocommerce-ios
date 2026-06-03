import Foundation

/// Errors specific to the file-based POS catalog API.
public enum POSCatalogFileError: Error {
    case downloadFailed(statusCode: Int?, contentType: String?, underlyingError: Error)
    case invalidResponse(statusCode: Int?, contentType: String?, underlyingError: Error)
}

extension POSCatalogFileError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let statusCode, _, _):
            if let statusCode {
                return "Catalog file download failed with HTTP status \(statusCode)"
            }
            return "Catalog file download failed"
        case .invalidResponse:
            return "Catalog file response could not be parsed"
        }
    }
}
