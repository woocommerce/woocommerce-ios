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


    /// This function checks the default site's API version and then displays a warning if the
    /// site's WC version is not valid.
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

        checkMinimumWooVersion(for: siteID) { (isValidWCVersion) in
            guard isValidWCVersion == false else {
                return
            }

            let fancyAlert = FancyAlertViewController.makeWooUpgradeAlertController()
            fancyAlert.modalPresentationStyle = .custom
            fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
            AppDelegate.shared.tabBarController?.present(fancyAlert, animated: true)
        }
    }

    /// This function simply checks the provided site's API version. No warning will be displayed to the user.
    ///
    /// - Parameters:
    ///     - siteID: The SiteID to perform a version check on
    ///     - completion: Closure to be executed upon completion (with a Bool parameter where `true` means the
    ///                   site's WC version is valid and `false` means it's a legacy version that must be upgraded).
    ///
    static func checkMinimumWooVersion(for siteID: Int, onCompletion: ((Bool) -> Void)? = nil) {
        let action = retrieveSiteAPIAction(siteID: siteID, onCompletion: onCompletion)
        StoresManager.shared.dispatch(action)
    }
}

private extension RequirementsChecker {

    /// Returns a `SettingAction.retrieveSiteAPI` action
    ///
    static func retrieveSiteAPIAction(siteID: Int, onCompletion: ((Bool) -> Void)? = nil) -> SettingAction {
        return SettingAction.retrieveSiteAPI(siteID: siteID) { (siteAPI, error) in
            guard let siteAPI = siteAPI else {
                DDLogError("⛔️ Could not successfully fetch API info for siteID \(siteID): \(String(describing: error))")
                onCompletion?(true)
                return
            }

            if siteAPI.highestWooVersion != .mark3 {
                DDLogWarn("⚠️ WC version older than v3.5 — highest API version: \(siteAPI.highestWooVersion.rawValue) for siteID: \(siteAPI.siteID)")
            }

            let isValidVersion = (siteAPI.highestWooVersion == .mark3)
            onCompletion?(isValidVersion)
        }
    }
}
