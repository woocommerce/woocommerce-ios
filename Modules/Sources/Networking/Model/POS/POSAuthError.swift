import Foundation

/// Error types returned by POS authentication endpoints.
///
/// Maps WooCommerce REST API error codes from `wc/v3/pos/auth/*` endpoints
/// to strongly typed Swift errors with relevant metadata.
///
public enum POSAuthError: Error, Equatable {

    /// The provided PIN is not valid.
    case invalidPIN

    /// Too many authentication attempts. Contains the number of seconds to wait before retrying.
    case rateLimited(retryAfter: Int)

    /// The approver does not have permission for this action.
    case approvalForbidden

    /// The requested approval action is not supported by the backend.
    case invalidAction

    /// The session has expired and a new PIN entry is required.
    case sessionExpired

    /// An unmapped error code was returned.
    case unknown(code: String, message: String)

    /// The response body could not be decoded into any known POS auth format.
    /// `preview` contains a truncated UTF-8 representation of the body for debugging.
    case malformedResponse(preview: String)
}

// MARK: - LocalizedError
//
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
        case .approvalForbidden:
            return NSLocalizedString(
                "posAuthError.approvalForbidden",
                value: "The approver does not have permission for this action.",
                comment: "Error shown when a POS manager lacks the required capability for approval"
            )
        case .invalidAction:
            return NSLocalizedString(
                "posAuthError.invalidAction",
                value: "This action is not supported for approval.",
                comment: "Error shown when the requested POS approval action is not recognized by the backend"
            )
        case .sessionExpired:
            return NSLocalizedString(
                "posAuthError.sessionExpired",
                value: "Your session has expired. Please enter your PIN again.",
                comment: "Error shown when the POS session has expired"
            )
        case .unknown(_, let message):
            return message
        case .malformedResponse:
            return NSLocalizedString(
                "posAuthError.malformedResponse",
                value: "We couldn't understand the response from the server. Please try again.",
                comment: "Error shown when the POS auth response body does not match any expected format"
            )
        }
    }
}

// MARK: - Factory
//
public extension POSAuthError {

    /// Attempts to create a `POSAuthError` from a generic `Error`.
    ///
    /// Unwraps the two shapes POS auth errors can arrive in:
    /// - `DotcomError.unknown(code, message, data)`: WPCOM Jetpack-tunneled requests
    ///   return HTTP 200 with an error body like
    ///   `{"error": "woocommerce_pos_invalid_pin", "message": "...", "data": {"status": 422}}`.
    ///   `DotcomValidator` converts that into `DotcomError.unknown` before the mapper runs.
    /// - `NetworkError.unacceptableStatusCode(_, response)` / `NetworkError.notFound` /
    ///   `NetworkError.timeout`: direct REST requests (application password) that fail
    ///   Alamofire's status validation return a `NetworkError` whose body decodes into
    ///   `{"code": "...", "message": "...", "data": {...}}`.
    ///
    /// Both shapes are normalized into a common `code` + `data` representation which is
    /// then matched against the known POS auth error codes.
    ///
    /// When the error is already a `POSAuthError` (e.g. thrown directly by the mapper),
    /// it's returned unchanged.
    static func from(_ error: Error) -> POSAuthError {
        if let posError = error as? POSAuthError {
            return posError
        }
        guard let details = POSAuthErrorDetails(error: error) else {
            return .unknown(code: "unknown", message: error.localizedDescription)
        }
        return details.asPOSAuthError()
    }
}

// MARK: - Error unwrapping
//
/// Canonical representation of the `code` + optional `message` + optional `data`
/// extracted from an upstream error (DotcomError, NetworkError, etc.).
///
/// Mirrors the pattern used by `PaymentsError`: unwrap once into a flat struct,
/// then map known codes to typed cases.
private struct POSAuthErrorDetails {
    let code: String
    let message: String?
    let data: [String: AnyDecodable]?

    init?(error: Error) {
        switch error {
        case let DotcomError.unknown(code, message, data):
            self.code = code
            self.message = message
            self.data = data
        case let networkError as NetworkError:
            guard let code = networkError.errorCode else {
                return nil
            }
            self.code = code
            self.message = nil
            self.data = networkError.errorData
        default:
            return nil
        }
    }

    func asPOSAuthError() -> POSAuthError {
        switch code {
        case POSAuthError.ErrorCodes.invalidPIN:
            return .invalidPIN
        case POSAuthError.ErrorCodes.rateLimited:
            return .rateLimited(retryAfter: retryAfterSeconds ?? POSAuthError.Constants.defaultRetryAfter)
        case POSAuthError.ErrorCodes.approvalForbidden:
            return .approvalForbidden
        case POSAuthError.ErrorCodes.invalidAction:
            return .invalidAction
        case POSAuthError.ErrorCodes.sessionExpired:
            return .sessionExpired
        default:
            return .unknown(code: code, message: message ?? code)
        }
    }

    private var retryAfterSeconds: Int? {
        guard let value = data?["retry_after"]?.value else { return nil }
        if let intValue = value as? Int {
            return intValue
        }
        if let doubleValue = value as? Double {
            return Int(doubleValue)
        }
        return nil
    }
}

// MARK: - Constants
//
extension POSAuthError {
    enum ErrorCodes {
        static let invalidPIN = "woocommerce_pos_invalid_pin"
        static let rateLimited = "woocommerce_pos_rate_limited"
        static let approvalForbidden = "woocommerce_pos_approval_forbidden"
        static let invalidAction = "woocommerce_pos_invalid_action"
        static let sessionExpired = "woocommerce_pos_session_expired"
    }

    enum Constants {
        static let defaultRetryAfter = 30
    }
}
