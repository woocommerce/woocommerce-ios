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


    /// Designated Initializer
    ///
    public init(username: String, authToken: String) {
        self.username = username
        self.authToken = authToken
    }
}


/// Equatable Support
///
public func ==(lhs: Credentials, rhs: Credentials) -> Bool {
    return lhs.authToken == rhs.authToken && lhs.username == rhs.username
}
