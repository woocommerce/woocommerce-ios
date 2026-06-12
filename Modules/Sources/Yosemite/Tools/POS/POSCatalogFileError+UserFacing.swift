import Foundation
import enum NetworkingCore.POSCatalogFileError

public extension Error {
    /// Returns `true` when the catalog file response facts indicate the host blocks direct access
    /// to the generated POS catalog file (e.g. an Apache `.htaccess` returning 403, or an HTML
    /// error page served instead of the catalog JSON).
    var isPOSCatalogFileBlockedError: Bool {
        switch self as? POSCatalogFileError {
        case .downloadFailed(let statusCode, let contentType):
            return statusCode == 403 || isHTMLContentType(contentType)
        case .invalidResponse(_, let contentType, let hasHTMLBody, _):
            return hasHTMLBody || isHTMLContentType(contentType)
        case nil:
            return false
        }
    }
}

/// Returns true when the response content type is `text/html` — a sign that the host served an
/// HTML error page instead of the catalog JSON.
private func isHTMLContentType(_ contentType: String?) -> Bool {
    guard let mediaType = contentType?
        .split(separator: ";", maxSplits: 1)
        .first?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased() else {
        return false
    }
    return mediaType == "text/html"
}
