import Foundation
import enum Networking.POSAuthError

extension Error {
    /// Extracts a user-facing error message for manager override PIN failures.
    ///
    /// Tries `POSAuthError` first (which has localized descriptions for invalid PIN,
    /// rate limiting, etc.), then falls back to `LocalizedError.errorDescription`,
    /// and finally to a generic localized "Invalid PIN" message.
    var posOverrideErrorMessage: String {
        if let posError = self as? POSAuthError {
            return posError.errorDescription ?? Localization.fallbackInvalidPIN
        }
        if let localizedError = self as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return Localization.fallbackInvalidPIN
    }
}

private enum Localization {
    static let fallbackInvalidPIN = NSLocalizedString(
        "pos.managerOverride.error.invalidPIN",
        value: "Invalid PIN",
        comment: "Fallback error message shown when a manager override PIN verification fails"
    )
}
