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
    
    public enum Host {
        case wpCom
        case selfHosted(url: URL)
        
        /// The default site URL
        ///
        private static let defaultSiteURL = URL(string: "https://wordpress.com")!
        
        var url: URL {
            switch self {
            case .wpCom:
                return Self.defaultSiteURL
            case .selfHosted(let url):
                return url
            }
        }
    }

    /// Designated initializer
    ///
    public init(authToken: String,
                isJetpackLogin: Bool,
                multifactor: Bool,
                host: Host = .wpCom) {
        self.authToken = authToken
        self.isJetpackLogin = isJetpackLogin
        self.multifactor = multifactor
        
        // We should consider changing the type of siteURL once we remove the deprecated initializer.
        // For now, and in order to avoid breaking existing code, we can leave it as it is.
        self.siteURL = host.url.path
    }
    
    /// Legacy  initializer, for backwards compatibility
    ///
    @available(*, deprecated, message: "Use init(authToken:isJetpackLogin:multifactor:host:) instead.")
    public init(authToken: String,
                isJetpackLogin: Bool,
                multifactor: Bool,
                siteURL: String) {
        self.authToken = authToken
        self.isJetpackLogin = isJetpackLogin
        self.multifactor = multifactor
        self.siteURL = !siteURL.isEmpty ? siteURL : Host.wpCom.url.path
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: WordPressComCredentials, rhs: WordPressComCredentials) -> Bool {
    return lhs.authToken == rhs.authToken && lhs.siteURL == rhs.siteURL
}
