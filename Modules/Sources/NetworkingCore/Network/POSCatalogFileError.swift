import Foundation

/// Errors specific to the file-based POS catalog API.
public enum POSCatalogFileError: Error {
    case downloadFailed(statusCode: Int, contentType: String?)
    /// `hasHTMLBody` is true when the response body's first non-whitespace byte is `<` —
    /// an HTML page where the catalog JSON was expected. It is the only response fact available
    /// for background downloads, which don't retain status code or content type.
    case invalidResponse(statusCode: Int?, contentType: String?, hasHTMLBody: Bool, underlyingError: Error)
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
