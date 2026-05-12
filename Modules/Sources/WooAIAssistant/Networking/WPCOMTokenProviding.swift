public protocol WPCOMTokenProviding: Sendable {
    /// Returns the WPCOM OAuth bearer for authenticating against
    /// public-api.wordpress.com. Throws when the app isn't running
    /// under WPCOM credentials (e.g. the merchant signed in with an
    /// application password).
    func token() async throws -> String
}
