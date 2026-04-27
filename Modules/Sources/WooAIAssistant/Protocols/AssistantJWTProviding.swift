import Foundation

/// Mints the WPCOM AI JWT the assistant transport layer presents on every
/// upstream request. The app target wraps the existing token-fetch path.
public protocol AssistantJWTProviding: Sendable {
    func currentJWT() async throws -> String
}
