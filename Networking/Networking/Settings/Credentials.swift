import Foundation

/// Authenticated Requests Credentials
///
public enum Credentials: Equatable {

    /// For WordPress.com credentials
    ///
    case wpcom(username: String, authToken: String, siteAddress: String)

    /// For .org site credentials
    ///
    case wporg(username: String, password: String, siteAddress: String)

    /// For WPCOM credentials
    ///
    public init(username: String, authToken: String, siteAddress: String? = nil) {
        self = .wpcom(username: username, authToken: authToken, siteAddress: siteAddress ?? Constants.placeholderSiteAddress)
    }

    /// For WPOrg credentials
    ///
    public init(username: String, password: String, siteAddress: String) {
        self = .wporg(username: username, password: password, siteAddress: siteAddress)
    }

    /// Convenience initializer. Assigns a UUID as a placeholder for the username.
    ///
    public init(authToken: String) {
        self.init(username: UUID().uuidString, authToken: authToken, siteAddress: Constants.placeholderSiteAddress)
    }

    /// Returns true if the username is a UUID placeholder.
    ///
    public func hasPlaceholderUsername() -> Bool {
        // Only WPCOM credentials will have placeholder `username`
        guard case let .wpcom(username, _, _) = self else {
            return false
        }
        return UUID(uuidString: username) != nil
    }

    /// Returns true if the siteAddress is a placeholder.
    ///
    public func hasPlaceholderSiteAddress() -> Bool {
        // Only WPCOM credentials will have placeholder `siteAddress`
        guard case let .wpcom(_, _, siteAddress) = self else {
            return false
        }
        return siteAddress == Constants.placeholderSiteAddress
    }
}

private extension Credentials {
    struct Constants {
        static let placeholderSiteAddress = "https://wordpress.com"
    }
}

// MARK: - Helpers to read `Credentials`
//
public extension Credentials {
    var username: String {
        switch self {
        case .wpcom(let username, _, _):
            return username
        case .wporg(let username, _, _):
            return username
        }
    }

    var siteAddress: String {
        switch self {
        case .wpcom(_, _, let siteAddress):
            return siteAddress
        case .wporg(_, _, let siteAddress):
            return siteAddress
        }
    }

    var secret: String {
        switch self {
        case .wpcom(_, let authToken, _):
            return authToken
        case .wporg(_, let password, _):
            return password
        }
    }
}
