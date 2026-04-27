/// Mints the WPCOM AI JWT the assistant transport layer presents on every upstream request.
public protocol AssistantJWTProviding: Sendable {
    func currentJWT() async throws -> String
}
