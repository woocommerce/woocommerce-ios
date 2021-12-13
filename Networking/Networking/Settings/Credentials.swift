import Foundation


/// Authenticated Requests Credentials
///
public struct Credentials: Equatable {

    /// WordPress.com Username
    ///
    public let username: String

    /// WordPress.com Authentication Token
    ///
    public let authToken: String

    /// Site Address
    ///
    public let siteAddress: String


    /// Designated Initializer
    ///
    public init(username: String, authToken: String, siteAddress: String) {
        self.username = username
        self.authToken = authToken
        self.siteAddress = siteAddress
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

private extension Credentials {
    struct Constants {
        static let placeholderSiteAddress = "https://wordpress.com"
    }
}
