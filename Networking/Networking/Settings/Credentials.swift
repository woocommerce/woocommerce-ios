import Foundation


/// Authenticated Requests Credentials
///
public struct Credentials: Equatable {

    /// WordPress.com Authentication Token
    ///
    public let authToken: String
}


/// Equatable Support
///
public func ==(lhs: Credentials, rhs: Credentials) -> Bool {
    return lhs.authToken == rhs.authToken
}
