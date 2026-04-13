import Foundation
import enum NetworkingCore.DotcomError

/// Categorizes the error shown in the store picker error screen.
/// Extracted as a standalone type for testability.
///
enum StorePickerErrorType: Equatable {
    /// The remote site returned a server error when verifying user permissions.
    case serverError
    /// Any other error (network issues, unknown errors, etc.)
    case generic

    /// Creates an error type from the underlying error returned by the role eligibility check.
    ///
    static func from(_ error: Error) -> StorePickerErrorType {
        if let dotcomError = error as? DotcomError,
           case .requestFailed = dotcomError {
            return .serverError
        }
        return .generic
    }

    /// Extracts a compact technical summary from a `DotcomError.requestFailed` data dictionary.
    /// Returns `nil` for non-DotcomError errors or when no useful data is available.
    ///
    static func technicalDetails(from error: Error) -> String? {
        guard let dotcomError = error as? DotcomError,
              case .requestFailed(let data) = dotcomError,
              let data else {
            return nil
        }

        var parts: [String] = []
        if let status = data["status"]?.value {
            parts.append("Status: \(status)")
        }
        if let errors = data["errors"]?.value as? [String: Any] {
            if let code = errors["code"] {
                parts.append("Error: \(code)")
            }
            if let message = errors["message"] {
                parts.append("\(message)")
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    var bodyText: String {
        switch self {
        case .serverError:
            return Localization.serverErrorBody
        case .generic:
            return Localization.genericBody
        }
    }

    private enum Localization {
        static let serverErrorBody = NSLocalizedString(
            "storePickerError.serverErrorBody",
            value: "There was a problem verifying your permissions. " +
                "Please contact your hosting provider for assistance, or reach out to us.",
            comment: "Body text for the store picker error screen when the site returns a server error")
        static let genericBody = NSLocalizedString(
            "storePickerError.genericBody",
            value: "Please try again or reach out to us and we'll be happy to assist you!",
            comment: "Body text for the default store picker error screen")
    }
}
