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


    /// This function fetches the current site's API and then displays a warning if WC REST v3 is not available.
    ///
    static func checkMinimumWooVersion() {
        guard StoresManager.shared.isAuthenticated, StoresManager.shared.needsDefaultStore == false else {
            return
        }
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID,
            siteID != 0 else {
                return
        }

        let action = SettingAction.retrieveSiteAPI(siteID: siteID) { (siteAPI, error) in
            guard error == nil else {
                DDLogWarn("⚠️ Could not successfully fetch API info for siteID \(siteID): \(String(describing: error))")
                return
            }
            guard let siteAPI = siteAPI, siteAPI.highestWooVersion != .mark3 else {
                return
            }

            DDLogWarn("⚠️ WC version older than v3.5 — highest API version: \(siteAPI.highestWooVersion.rawValue) for siteID: \(siteID)")
            let fancyAlert = FancyAlertViewController.makeWooUpgradeAlertController()
            fancyAlert.modalPresentationStyle = .custom
            fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
            AppDelegate.shared.tabBarController?.present(fancyAlert, animated: true)
        }

        StoresManager.shared.dispatch(action)
    }
}
