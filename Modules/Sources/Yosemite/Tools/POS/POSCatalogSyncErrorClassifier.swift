import Foundation
import GRDB
import enum NetworkingCore.NetworkError
import enum NetworkingCore.DotcomError
import enum Alamofire.AFError

/// Classifies errors from catalog sync operations for analytics tracking.
/// This classifier has access to concrete error types from Storage and Networking layers.
enum POSCatalogSyncErrorClassifier {
    /// Classifies a sync error into an analytics-friendly error type string
    static func classify(_ error: Error) -> String {
        // Check for GRDB DatabaseError (has actual type information)
        if let dbError = error as? DatabaseError {
            return classifyDatabaseError(dbError)
        }

        // Check for Alamofire errors (may wrap other errors)
        if let afError = error as? AFError {
            return classifyAFError(afError)
        }

        // Check for cancellation errors
        if error is CancellationError {
            return "request_cancelled"
        }

        // Check for network errors
        if let networkError = error as? NetworkError {
            return classifyNetworkError(networkError)
        }

        // Check for URLError
        if let urlError = error as? URLError {
            return classifyURLError(urlError)
        }

        // Check for authentication errors
        if let dotcomError = error as? DotcomError {
            return classifyDotcomError(dotcomError)
        }

        // Check for parsing/decoding errors
        if error is DecodingError {
            return "catalog_integrity"
        }

        // Fallback: Check NSError domain/code for test mocks or wrapped errors
        let nsError = error as NSError

        // Check HTTP status codes
        if nsError.code == 401 || nsError.code == 403 {
            return "authentication_error"
        }

        // Check domain for network-related errors (for mocks)
        if nsError.domain.contains("Network") || nsError.domain.contains("URLError") {
            return "network_error"
        }

        // Check domain for database errors (for mocks)
        if nsError.domain.contains("GRDB") || nsError.domain.contains("Database") {
            if nsError.code == 13 {
                return "insufficient_free_space"
            }
            return "database_error"
        }

        // Default to unexpected error
        DDLogWarn("⚠️ Unclassified catalog sync error: domain=\(nsError.domain), code=\(nsError.code), \(error)")
        return "unexpected_error"
    }

    // MARK: - Private Helpers

    private static func classifyAFError(_ error: AFError) -> String {
        // Check for explicit cancellation
        if error.isExplicitlyCancelledError {
            return "request_cancelled"
        }

        // Check for session task errors (wraps URLError and other Foundation errors)
        if case .sessionTaskFailed(let underlyingError) = error {
            // Recursively classify the underlying error
            return classify(underlyingError)
        }

        // Check for response validation errors (HTTP status codes)
        if case .responseValidationFailed(let reason) = error {
            switch reason {
            case .unacceptableStatusCode(let statusCode):
                if statusCode == 401 || statusCode == 403 {
                    return "authentication_error"
                }
                return "network_error"
            default:
                return "network_error"
            }
        }

        // Check for invalid URL
        if case .invalidURL = error {
            return "network_error"
        }

        // Other Alamofire errors are generally network-related
        return "network_error"
    }

    private static func classifyNetworkError(_ error: NetworkError) -> String {
        switch error {
        case .timeout:
            return "network_timeout"
        case .unacceptableStatusCode(let statusCode, _):
            if statusCode == 401 || statusCode == 403 {
                return "authentication_error"
            }
            return "network_error"
        default:
            return "network_error"
        }
    }

    private static func classifyDatabaseError(_ error: DatabaseError) -> String {
        switch error.resultCode {
        case .SQLITE_FULL:
            return "insufficient_free_space"
        case .SQLITE_CORRUPT, .SQLITE_NOTADB:
            return "database_corruption"
        case .SQLITE_CONSTRAINT:
            return "database_constraint_violation"
        default:
            return "database_error"
        }
    }

    private static func classifyURLError(_ error: URLError) -> String {
        switch error.code {
        case .timedOut:
            return "network_timeout"
        default:
            return "network_error"
        }
    }

    private static func classifyDotcomError(_ error: DotcomError) -> String {
        // DotcomError has HTTP status codes
        switch error {
        case .unauthorized:
            return "authentication_error"
        default:
            return "network_error"
        }
    }
}
