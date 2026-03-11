import Foundation

// MARK: - WordPress.com Site Info
//
public class WordPressComSiteInfo {

    /// Site's Name!
    ///
    public let name: String

    /// Tagline.
    ///
    public let tagline: String

    /// Public URL.
    ///
    public let url: String

    /// Indicates if Jetpack is available, or not.
    ///
    public let hasJetpack: Bool

    /// Indicates if Jetpack is active, or not.
    ///
    public let isJetpackActive: Bool

    /// Indicates if Jetpack is connected, or not.
    ///
    public let isJetpackConnected: Bool

    /// URL of the Site's Blavatar.
    ///
    public let icon: String

    /// Indicates whether the site is WordPressDotCom, or not.
    ///
    public let isWPCom: Bool

    /// Indicates whether the site is a Commerce Garden (CIAB) site, or not.
    ///
    public let isCommerceGarden: Bool

    /// Inidcates wheter the site is WordPress, or not.
    ///
    public let isWP: Bool

    /// Inidcates whether the site exists, or not.
    ///
    public let exists: Bool

    public init(name: String,
                tagline: String,
                url: String,
                hasJetpack: Bool,
                isJetpackActive: Bool,
                isJetpackConnected: Bool,
                icon: String,
                isWPCom: Bool,
                isCommerceGarden: Bool = false,
                isWP: Bool,
                exists: Bool) {
        self.name = name
        self.tagline = tagline
        self.url = url
        self.hasJetpack = hasJetpack
        self.isJetpackActive = isJetpackActive
        self.isJetpackConnected = isJetpackConnected
        self.icon = icon
        self.isWPCom = isWPCom
        self.isCommerceGarden = isCommerceGarden
        self.isWP = isWP
        self.exists = exists
    }

    /// Initializes the current SiteInfo instance with a raw dictionary.
    ///
    public init(remote: [AnyHashable: Any]) {
        name                = remote["name"] as? String                 ?? ""
        tagline             = remote["description"] as? String          ?? ""
        url                 = remote["urlAfterRedirects"] as? String    ?? ""
        hasJetpack          = remote["hasJetpack"] as? Bool             ?? false
        isJetpackActive     = remote["isJetpackActive"] as? Bool        ?? false
        isJetpackConnected  = remote["isJetpackConnected"] as? Bool     ?? false
        icon                = remote["icon.img"] as? String             ?? ""
        isWPCom             = remote["isWordPressDotCom"] as? Bool      ?? false
        isCommerceGarden    = remote["isCommerceGarden"] as? Bool      ?? false
        isWP                = remote["isWordPress"] as? Bool            ?? false
        exists              = remote["exists"] as? Bool                 ?? false
    }
}
