import Foundation
import Networking

/// SitePostAction: Defines all of the Actions supported by the SitePostStore.
///
public enum SitePostAction: Action {
    
    /// Get site post password
    ///
    case getSitePostPassword(siteID: Int64, postID: Int64, onCompletion: (_ password: String?, _ error: Error?) -> Void)
    
    /// Update site post password
    ///
    case updateSitePostPassword(siteID: Int64, postID: Int64, password: String, onCompletion: (_ password: String?, _ error: Error?) -> Void)
}
