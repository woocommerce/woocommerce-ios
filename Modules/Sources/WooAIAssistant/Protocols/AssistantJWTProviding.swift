/// Mints the WPCOM AI JWT the assistant transport layer presents on every upstream request.
/// `invalidate()` lets the chat client throw away a token the upstream reported as expired
/// before its `exp` (clock skew or revocation) so the next `currentJWT()` mints fresh.
public protocol AssistantJWTProviding: Sendable {
    func currentJWT() async throws -> String
    func invalidate() async
}

public extension AssistantJWTProviding {
    /// No-op default so non-caching stubs (in-memory test doubles, app-password adaptors)
    /// don't have to implement an invalidation hook they have nothing to invalidate.
    func invalidate() async {}
}
