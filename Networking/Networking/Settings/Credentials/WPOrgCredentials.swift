import Foundation

/// WPOrg authentication Credentials
///
public struct WPOrgCredentials: Credentials {
    /// WordPress.com Username
    ///
    public let username: String

    /// Holds .org site credentials password
    ///
    public let secret: WPOrgSecret

    /// Site Address
    ///
    public let siteAddress: String

    /// Designated Initializer
    ///
    public init(username: String, password: String, siteAddress: String) {
        self.username = username
        self.secret = WPOrgSecret(password: password)
        self.siteAddress = siteAddress
    }
}
