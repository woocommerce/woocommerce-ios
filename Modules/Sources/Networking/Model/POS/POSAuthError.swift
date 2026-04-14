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
        }
    }
}

// MARK: - Factory
//
public extension POSAuthError {

    /// Attempts to create a `POSAuthError` from a generic `Error`.
    ///
    /// Inspects `NetworkError` response data for known POS error codes and
    /// extracts `retry_after` from the `data` payload when rate limited.
    ///
    static func from(_ error: Error) -> POSAuthError {
        guard let networkError = error as? NetworkError else {
            return .unknown(code: "unknown", message: error.localizedDescription)
        }

        guard let code = networkError.errorCode else {
            return .unknown(code: "unknown", message: error.localizedDescription)
        }

        switch code {
        case ErrorCodes.invalidPIN:
            return .invalidPIN
        case ErrorCodes.rateLimited:
            let retryAfter = networkError.retryAfterSeconds ?? Constants.defaultRetryAfter
            return .rateLimited(retryAfter: retryAfter)
        case ErrorCodes.approvalForbidden:
            return .approvalForbidden
        case ErrorCodes.invalidAction:
            return .invalidAction
        case ErrorCodes.sessionExpired:
            return .sessionExpired
        default:
            let message = networkError.localizedDescription
            return .unknown(code: code, message: message)
        }
    }
}

// MARK: - NetworkError Helper
//
private extension NetworkError {
    /// Extracts the `retry_after` value from the error response `data` payload.
    var retryAfterSeconds: Int? {
        guard let data = errorData,
              let retryAfterValue = data["retry_after"]?.value as? Int else {
            // Also try Double in case the backend sends a numeric value
            if let data = errorData,
               let doubleValue = data["retry_after"]?.value as? Double {
                return Int(doubleValue)
            }
            return nil
        }
        return retryAfterValue
    }
}

// MARK: - Constants
//
private extension POSAuthError {
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
