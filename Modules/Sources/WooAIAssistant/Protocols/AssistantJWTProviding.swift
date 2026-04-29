public protocol AssistantJWTProviding: Sendable {
    func currentJWT() async throws -> String
    func invalidate() async
}

public extension AssistantJWTProviding {
    // Default for non-caching conformers (e.g. test stubs) that have no token to drop.
    func invalidate() async {}
}
