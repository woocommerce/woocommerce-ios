import Foundation


/// Authenticated Requests Credentials
///
public struct Credentials: Equatable {

    /// WordPress.com Authentication Token
    ///
    public let authToken: String

    /// WordPress.com Username
    ///
    public let username: String


    /// Designated Initializer
    ///
    public init(authToken: String, username: String) {
        self.authToken = authToken
        self.username =  username
    }
}


/// Equatable Support
///
public func ==(lhs: Credentials, rhs: Credentials) -> Bool {
    return lhs.authToken == rhs.authToken
}
