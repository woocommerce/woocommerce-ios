import Foundation

extension CachedJWT {
    enum Localization {
        static let invalidJWT = NSLocalizedString(
            "ai.assistant.networking.jwt.invalid",
            value: "The assistant authentication token is invalid.",
            comment: "Shown when the JWT minted by the proxy is malformed or missing required fields. Diagnostic detail is logged via DDLogError."
        )
    }
}
