
// MARK: - WordPress Credentials
//
public enum WordPressCredentials {

    /// WordPress.org Site Credentials.
    ///
    case wporg(username: String, password: String, xmlrpc: String, options: [AnyHashable: Any])

    /// WordPress.com Site Credentials.
    ///
    case wpcom(authToken: String, isJetpackLogin: Bool, multifactor: Bool, siteURL: String)
}
