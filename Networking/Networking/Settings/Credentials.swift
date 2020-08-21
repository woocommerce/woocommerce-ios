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

    /// Returns true if the username is a UUID placeholder.
    ///
    public func hasPlaceholderUsername() -> Bool {
        return UUID(uuidString: username) != nil
    }
}


/// Equatable Support
///
public func ==(lhs: Credentials, rhs: Credentials) -> Bool {
    return lhs.authToken == rhs.authToken && lhs.username == rhs.username
}
