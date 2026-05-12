public protocol WPCOMTokenProviding: Sendable {
    func token() async throws -> String
}
