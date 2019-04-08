import Foundation

// MARK: - WordPress.com Credentials
//
public struct WordPressComCredentials: Equatable {

    /// WordPress.com authentication token
    ///
    public let authToken: String

    /// Is this a Jetpack-connected site?
    ///
    public let isJetpackLogin: Bool

    /// Is 2-factor Authentication Enabled?
    ///
    public let multifactor: Bool

    /// The site address used during login
    ///
    public var siteURL: String

    /// Designated initializer
    ///
    public init(authToken: String,
                isJetpackLogin: Bool,
                multifactor: Bool,
                siteURL: String) {
        self.authToken = authToken
        self.isJetpackLogin = isJetpackLogin
        self.multifactor = multifactor
        self.siteURL = !siteURL.isEmpty ? siteURL : "https://wordpress.com"
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: WordPressComCredentials, rhs: WordPressComCredentials) -> Bool {
    return lhs.authToken == rhs.authToken && lhs.siteURL == rhs.siteURL
}
