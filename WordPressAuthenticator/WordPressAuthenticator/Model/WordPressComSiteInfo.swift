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

    /// Inidcates wheter the site is WordPress, or not.
    ///
    public let isWP: Bool

    /// Inidcates whether the site exists, or not.
    ///
    public let exists: Bool



    /// Initializes the current SiteInfo instance with a raw dictionary.
    ///
    public init(remote: [AnyHashable: Any]) {
        name                = remote["name"] as? String ?? ""
        tagline             = remote["description"] as? String ?? ""
        url                 = remote["urlAfterRedirects"] as? String ?? ""
        hasJetpack          = remote["hasJetpack"] as? Int == 1 ? true: false
        isJetpackActive     = remote["isJetpackActive"] as? Int == 1 ? true: false
        isJetpackConnected  = remote["isJetpackConnected"] as? Int == 1 ? true: false
        icon                = remote["icon.img"] as? String ?? ""
        isWPCom             = remote["isWordPressDotCom"] as? Int == 1 ? true: false
        isWP                = remote["isWordPress"] as? Int == 1 ? true: false
        exists              = remote["exists"] as? Int == 1 ? true: false
    }
}
