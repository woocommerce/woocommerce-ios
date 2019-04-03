import Foundation
import Networking


/// SettingAction: Defines all of the Actions supported by the SettingStore.
///
public enum SettingAction: Action {

    /// Synchronizes the site's general settings
    ///
    case synchronizeGeneralSiteSettings(siteID: Int, onCompletion: (Error?) -> Void)

    /// Synchronizes the site's product settings
    ///
    case synchronizeProductSiteSettings(siteID: Int, onCompletion: (Error?) -> Void)

    /// Retrieves the site API details (used to determine the WC version)
    ///
    case retrieveSiteAPI(siteID: Int, onCompletion: (SiteAPI?, Error?) -> Void)
}
