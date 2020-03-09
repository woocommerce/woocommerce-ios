import Foundation
import UIKit
import Yosemite
import WordPressUI


/// Result Enum for the RequirementsChecker
///
enum RequirementCheckResult: Int, CaseIterable {

    /// The installed version of WC is valid
    ///
    case validWCVersion

    /// The installed version of WC is NOT valid
    ///
    case invalidWCVersion

    /// The response returned from the server successfully however it was empty or missing information
    /// that prevents us from verifing the WC version
    ///
    case empty

    /// The request to the server timed out or resulted in an error
    ///
    case error
}


/// Responsible for checking the minimum requirements for the app and its features!
///
class RequirementsChecker {

    /// Private: NO-OP
    ///
    private init() { }


    /// This function checks the default site's API version and then displays a warning if the
    /// site's WC version is not valid.
    ///
    /// NOTE: When checking the default site's WC version, if 1) an error occurs or 2) the server response is invalid,
    ///       the WC version alert will *not* be displayed.
    ///
    static func checkMinimumWooVersionForDefaultStore() {
        guard ServiceLocator.stores.isAuthenticated else {
            return
        }
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID, siteID != 0 else {
            DDLogWarn("⚠️ Cannot check WC version on default store — default siteID is nil or 0.")
            return
        }

        checkMinimumWooVersion(for: siteID) { (result, error) in
            switch result {
            case .invalidWCVersion:
                displayWCVersionAlert()
            default:
                break
            }
        }
    }

    /// This function simply checks the provided site's API version. No warning will be displayed to the user.
    ///
    /// - parameter siteID: The SiteID to perform a version check on
    /// - parameter onCompletion: Closure to be executed upon completion
    /// - parameter result: Closure param that is the result of the requirement check
    /// - parameter error: Closure param that is any error that occured while checking the WC version
    ///
    static func checkMinimumWooVersion(for siteID: Int64, onCompletion: ((_ result: RequirementCheckResult, _ error: Error?) -> Void)? = nil) {
        let action = retrieveSiteAPIAction(siteID: siteID, onCompletion: onCompletion)
        ServiceLocator.stores.dispatch(action)
    }
}


// MARK: - Private helpers
//
private extension RequirementsChecker {

    /// Display the WC version alert
    ///
    static func displayWCVersionAlert() {
        let fancyAlert = FancyAlertViewController.makeWooUpgradeAlertController()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        AppDelegate.shared.tabBarController?.present(fancyAlert, animated: true)
    }

    /// Returns a `SettingAction.retrieveSiteAPI` action
    ///
    static func retrieveSiteAPIAction(siteID: Int64, onCompletion: ((RequirementCheckResult, Error?) -> Void)? = nil) -> SettingAction {
        return SettingAction.retrieveSiteAPI(siteID: siteID) { (siteAPI, error) in
            guard error == nil else {
                DDLogError("⛔️ An error occurred while fetching API info for siteID \(siteID): \(String(describing: error))")
                onCompletion?(.error, error)
                return
            }
            guard let siteAPI = siteAPI else {
                DDLogWarn("⚠️ Empty or invalid response while fetching API info for siteID \(siteID))")
                onCompletion?(.empty, nil)
                return
            }

            if siteAPI.highestWooVersion == .mark3 {
                onCompletion?(.validWCVersion, nil)
            } else {
                DDLogWarn("⚠️ WC version older than v3.5 — highest API version: \(siteAPI.highestWooVersion.rawValue) for siteID: \(siteAPI.siteID)")
                onCompletion?(.invalidWCVersion, nil)
            }
        }
    }
}
