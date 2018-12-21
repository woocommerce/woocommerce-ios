import Foundation
import Networking


// MARK: - SettingAction: Defines all of the Actions supported by the SettingStore.
//
public enum SettingAction: Action {
    case retrieveSiteSettings(siteID: Int, onCompletion: (Error?) -> Void)
    case retrieveSiteAPI(siteID: Int, onCompletion: (SiteAPI?, Error?) -> Void)
}
