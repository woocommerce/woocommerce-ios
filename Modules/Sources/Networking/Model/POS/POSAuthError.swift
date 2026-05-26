import Foundation

/// Error types surfaced by the POS PIN validation layer.
///
/// In the M1 server-side design, PIN validation is local: there is no remote
/// PIN endpoint to error against. These cases cover:
/// - Locally raised errors (invalid PIN, rate limit) from the permission provider
/// - Errors returned by the `GET /wc-pos/v1/staff` fetch (unmapped server errors
///   or undecodable responses)
public enum POSAuthError: Error, Equatable {

    /// The provided PIN did not match any cached staff member's hash.
    case invalidPIN

    /// Too many failed PIN attempts in a row. Contains the number of seconds to wait before retrying.
    case rateLimited(retryAfter: Int)

    /// An unmapped error code was returned by the staff fetch endpoint.
    case unknown(code: String, message: String)

    /// The staff fetch response body could not be decoded.
    /// `preview` contains a truncated UTF-8 representation of the body for debugging.
    case malformedResponse(preview: String)
}

// MARK: - LocalizedError

extension POSAuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPIN:
            return NSLocalizedString(
                "posAuthError.invalidPIN",
                value: "The provided PIN is not valid.",
                comment: "Error shown when a POS staff member enters an incorrect PIN"
            )
        case .rateLimited(let seconds):
            let format = NSLocalizedString(
                "posAuthError.rateLimited",
                value: "Too many attempts. Try again in %1$d seconds.",
                comment: "Error shown when POS PIN entry is rate limited. %1$d is the number of seconds to wait."
            )
            return String.localizedStringWithFormat(format, seconds)
        case .unknown(_, let message):
            return message
        case .malformedResponse:
            return NSLocalizedString(
                "posAuthError.malformedResponse",
                value: "We couldn't understand the response from the server. Please try again.",
                comment: "Error shown when the POS staff fetch response body does not match any expected format"
            )
        }
    }
}

// MARK: - Factory

public extension POSAuthError {

    /// Attempts to create a `POSAuthError` from a generic `Error` raised by the staff fetch.
    ///
    /// When the error is already a `POSAuthError`, it's returned unchanged. Otherwise
    /// it's mapped to `.unknown` with a best-effort code/message.
    static func from(_ error: Error) -> POSAuthError {
        if let posError = error as? POSAuthError {
            return posError
        }
        guard let details = POSAuthErrorDetails(error: error) else {
            return .unknown(code: "unknown", message: error.localizedDescription)
        }
        return .unknown(code: details.code, message: details.message ?? details.code)
    }
}

// MARK: - Error unwrapping

private struct POSAuthErrorDetails {
    let code: String
    let message: String?

    init?(error: Error) {
        switch error {
        case let DotcomError.unknown(code, message, _):
            self.code = code
            self.message = message
        case let networkError as NetworkError:
            guard let code = networkError.errorCode else {
                return nil
            }
            self.code = code
            self.message = nil
        default:
            return nil
        }
    }
}
