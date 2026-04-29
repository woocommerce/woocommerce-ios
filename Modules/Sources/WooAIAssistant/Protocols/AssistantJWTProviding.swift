public protocol AssistantJWTProviding: Sendable {
    func currentJWT() async throws -> String
    func invalidate() async
}

public extension AssistantJWTProviding {
    func invalidate() async {}
}
