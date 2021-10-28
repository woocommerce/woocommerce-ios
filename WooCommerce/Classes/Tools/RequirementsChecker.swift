import Foundation
import UIKit
import Yosemite
import WordPressUI
import class Networking.UserAgent


/// Result Enum for the RequirementsChecker
///
enum RequirementCheckResult: Int, CaseIterable {

    /// The installed version of WC is valid
    ///
    case validWCVersion

    /// The installed version of WC is NOT valid
    ///
    case invalidWCVersion
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

        checkMinimumWooVersion(for: siteID) { result in
            if case .success(.invalidWCVersion) = result {
                displayWCVersionAlert()
            }
        }
    }

    /// This function simply checks the provided site's API version. No warning will be displayed to the user.
    ///
    /// - parameter siteID: The SiteID to perform a version check on
    /// - parameter onCompletion: Closure to be executed upon completion with the result of the requirement check
    ///
    static func checkMinimumWooVersion(for siteID: Int64, onCompletion: ((Result<RequirementCheckResult, Error>) -> Void)? = nil) {
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
    static func retrieveSiteAPIAction(siteID: Int64, onCompletion: ((Result<RequirementCheckResult, Error>) -> Void)? = nil) -> SettingAction {
        return SettingAction.retrieveSiteAPI(siteID: siteID) { result in
            switch result {
            case .success(let siteAPI):
                if siteAPI.telemetryIsAvailable {
                    sendTelemetryIfNeeded(siteID: siteID)
                }
                if siteAPI.highestWooVersion == .mark3 {
                    onCompletion?(.success(.validWCVersion))
                } else {
                    DDLogWarn("⚠️ WC version older than v3.5 — highest API version: \(siteAPI.highestWooVersion.rawValue) for siteID: \(siteAPI.siteID)")
                    onCompletion?(.success(.invalidWCVersion))
                }
            case .failure(let error):
                DDLogError("⛔️ An error occurred while fetching API info for siteID \(siteID): \(String(describing: error))")
                onCompletion?(.failure(error))
            }
        }
    }

    /// Dispatches a `TelemetryAction.sendTelemetry` action
    ///
    static func sendTelemetryIfNeeded(siteID: Int64) {
        let minimalIntervalBetweenReports: TimeInterval = 60*60*24
        if let telemetryLastReportedTime = UserDefaults.standard[.telemetryLastReportedTime] as? Date,
           Date().timeIntervalSince(telemetryLastReportedTime) < minimalIntervalBetweenReports,
           siteID == UserDefaults.standard[.telemetryLastReportedStoreID] {
            // send telemetry for same store only once in 24h
            return
        }

        let action = TelemetryAction.sendTelemetry(siteID: siteID, versionString: UserAgent.bundleShortVersion) { result in
            switch result {
            case .success:
                UserDefaults.standard[.telemetryLastReportedTime] = Date()
                UserDefaults.standard[.telemetryLastReportedStoreID] = siteID
                DDLogInfo("Successfully sent telemetry for siteID: \(siteID).")
            case .failure(let error):
                DDLogError("⛔️ Failed to send telemetry for siteID: \(siteID). Error: \(error)")
            }
        }
        ServiceLocator.stores.dispatch(action)
    }
}
