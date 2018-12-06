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

        checkMinimumWooVersion(for: siteID) { (isValidWCVersion, error) in
            guard error == nil, isValidWCVersion == false else {
                // Let's not display the alert if there is an error
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
    /// - parameter siteID: The SiteID to perform a version check on
    /// - parameter onCompletion: Closure to be executed upon completion
    /// - parameter isValidWCVersion: a Bool parameter where `true` means the site's WC version is valid and `false` means it's a legacy version that must be upgraded
    /// - parameter error: Any error that occured while checking the WC version
    ///
    /// NOTE: If an error occurs while checking the site WC version, we will send 'false' back inside the closure along
    ///       with the error itself.
    ///
    static func checkMinimumWooVersion(for siteID: Int, onCompletion: ((_ isValidWCVersion: Bool, _ error: Error?) -> Void)? = nil) {
        let action = retrieveSiteAPIAction(siteID: siteID, onCompletion: onCompletion)
        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Private helpers
//
private extension RequirementsChecker {

    /// Returns a `SettingAction.retrieveSiteAPI` action
    ///
    static func retrieveSiteAPIAction(siteID: Int, onCompletion: ((Bool, Error?) -> Void)? = nil) -> SettingAction {
        return SettingAction.retrieveSiteAPI(siteID: siteID) { (siteAPI, error) in
            guard let siteAPI = siteAPI else {
                DDLogError("⛔️ Could not successfully fetch API info for siteID \(siteID): \(String(describing: error))")

                // By default, send `false` back for errors
                onCompletion?(false, error)
                return
            }

            if siteAPI.highestWooVersion != .mark3 {
                DDLogWarn("⚠️ WC version older than v3.5 — highest API version: \(siteAPI.highestWooVersion.rawValue) for siteID: \(siteAPI.siteID)")
            }

            let isValidVersion = (siteAPI.highestWooVersion == .mark3)
            onCompletion?(isValidVersion, nil)
        }
    }
}
