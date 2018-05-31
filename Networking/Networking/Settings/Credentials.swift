import Foundation


/// Authenticated Requests Credentials
///
public struct Credentials: Equatable {

    /// WordPress.com Authentication Token
    ///
    public let authToken: String

    /// Designated Initializer
    ///
    public init(authToken: String) {
        self.authToken = authToken
    }
}


/// Equatable Support
///
public func ==(lhs: Credentials, rhs: Credentials) -> Bool {
    return lhs.authToken == rhs.authToken
}
