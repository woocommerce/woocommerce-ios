import Foundation

/// Authenticated Requests Credentials
///
public struct Credentials: Equatable {

    /// Type of authentication wpcom/wporg
    ///
    public enum AuthenticationType: Equatable {
        /// Holds WordPress.com Authentication Token
        ///
        case wpcom(authToken: String)

        /// Holds .org site credentials password
        ///
        case wporg(password: String)
    }

    /// Authentication type
    ///
    public let authenticationType: AuthenticationType

    /// WordPress.com Username
    ///
    public let username: String

    /// Site Address
    ///
    public let siteAddress: String

    /// WordPress.com Authentication Token
    ///
    public var authToken: String? {
        guard case let .wpcom(authToken) = authenticationType else {
            return nil
        }
        return authToken
    }

    /// Designated Initializer
    ///
    public init(username: String, authToken: String, siteAddress: String? = nil) {
        self.username = username
        self.siteAddress = siteAddress ?? Constants.placeholderSiteAddress
        self.authenticationType = .wpcom(authToken: authToken)
    }

    /// For WPOrg credentials
    ///
    public init(username: String, password: String, siteAddress: String) {
        self.username = username
        self.siteAddress = siteAddress
        self.authenticationType = .wporg(password: password)
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
