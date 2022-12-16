import Foundation

/// WPCOM authentication Credentials
///
public struct WPCOMCredentials: Credentials {
    /// WordPress.com Username
    ///
    public let username: String

    /// WordPress.com secret (Holds the authentication token)
    ///
    public let secret: WPCOMSecret

    /// WordPress.com Authentication Token
    ///
    public var authToken: String {
        secret.authToken
    }

    /// Site Address
    ///
    public let siteAddress: String

    /// Designated Initializer
    ///
    public init(username: String, authToken: String, siteAddress: String? = nil) {
        self.username = username
        self.secret = WPCOMSecret(authToken: authToken)
        self.siteAddress = siteAddress ?? Constants.placeholderSiteAddress
    }

    /// Convenience initializer. Assigns a UUID as a placeholder for the username.
    ///
    public init(authToken: String) {
        self.init(username: UUID().uuidString, authToken: authToken, siteAddress: Constants.placeholderSiteAddress)
    }

    /// Returns true if the username is a UUID placeholder.
    ///
    public func hasPlaceholderUsername() -> Bool {
        return UUID(uuidString: username) != nil
    }

    /// Returns true if the siteAddress is a placeholder.
    ///
    public func hasPlaceholderSiteAddress() -> Bool {
        return siteAddress == Constants.placeholderSiteAddress
    }
}

private extension WPCOMCredentials {
    struct Constants {
        static let placeholderSiteAddress = "https://wordpress.com"
    }
}
