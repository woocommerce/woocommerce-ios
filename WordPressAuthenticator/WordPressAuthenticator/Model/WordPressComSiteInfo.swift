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

    /// URL of the Site's Blavatar.
    ///
    public let icon: String
    
    /// Indicates whether the site is WordPressDotCom, or not.
    ///
    public let isWPCom: Bool



    /// Initializes the current SiteInfo instance with a raw dictionary.
    ///
    public init(remote: [AnyHashable: Any]) {
        name        = remote["name"] as? String         ?? ""
        tagline     = remote["description"] as? String  ?? ""
        url         = remote["URL"] as? String          ?? ""
        hasJetpack  = remote["hasJetpack"] as? Bool     ?? false
        icon        = remote["icon.img"] as? String     ?? ""
        isWPCom     = remote["isWordPressDotCom"] as? Bool ?? false
        
    }
}
