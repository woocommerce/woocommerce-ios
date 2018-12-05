import Foundation
import UIKit
import Yosemite
import WordPressUI


/// Responsible for checking the minimum requirements for the app and it's features!
///
class RequirementsChecker {

    /// Private: NO-OP
    ///
    private init() { }


    /// This function fetches the default site's API and then displays a warning if WC REST v3 is not available.
    ///
    static func checkMinimumWooVersionForDefaultStore() {
        guard StoresManager.shared.isAuthenticated else {
            DDLogWarn("⚠️ Cannot check WC version on default store — user is not authenticated.")
            return
        }
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID, siteID != 0 else {
            DDLogWarn("⚠️ Cannot check WC version on default store — default siteID is nil or 0.")
            return
        }

        checkMinimumWooVersion(for: siteID)
    }

    /// This function fetches the provided site's API and then displays a warning if WC REST v3 is not available.
    ///
    static func checkMinimumWooVersion(for siteID: Int, onCompletion: ((SiteAPI?) -> Void)? = nil) {
        let action = retrieveSiteAPIAction(siteID: siteID, onCompletion: onCompletion)
        StoresManager.shared.dispatch(action)
    }
}

private extension RequirementsChecker {

    /// Returns a `SettingAction.retrieveSiteAPI` action
    ///
    static func retrieveSiteAPIAction(siteID: Int, onCompletion: ((SiteAPI?) -> Void)? = nil) -> SettingAction {
        return SettingAction.retrieveSiteAPI(siteID: siteID) { (siteAPI, error) in
            guard let siteAPI = siteAPI else {
                DDLogWarn("⚠️ Could not successfully fetch API info for siteID \(siteID): \(String(describing: error))")
                onCompletion?(nil)
                return
            }

            if siteAPI.highestWooVersion != .mark3 {
                DDLogWarn("⚠️ WC version older than v3.5 — highest API version: \(siteAPI.highestWooVersion.rawValue) for siteID: \(siteAPI.siteID)")
            }

            let fancyAlert = FancyAlertViewController.makeWooUpgradeAlertController()
            fancyAlert.modalPresentationStyle = .custom
            fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
            AppDelegate.shared.tabBarController?.present(fancyAlert, animated: true)

            onCompletion?(siteAPI)
        }
    }
}
