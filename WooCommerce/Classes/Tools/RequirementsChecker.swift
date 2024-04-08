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

    /// The site is running an expired WPCom plan
    case expiredWPComPlan
}


/// Responsible for checking the minimum requirements for the app and its features!
///
final class RequirementsChecker {

    private let stores: StoresManager
    private let baseViewController: UIViewController?

    init(stores: StoresManager = ServiceLocator.stores,
         baseViewController: UIViewController? = nil) {
        self.stores = stores
        self.baseViewController = baseViewController
    }

    /// This function checks the default site's API version and then displays a warning if the
    /// site's WC version is not valid.
    ///
    /// If the site is WPCom, the site plan is fetched when minimum Woo version check fails
    /// in order to determine if the site is running on an expired plan.
    ///
    func checkSiteEligibility(for site: Site, onCompletion: ((Result<RequirementCheckResult, Error>) -> Void)? = nil) {
        /// When a site plan expires, after 8 days the site is reverted to a simple site.
        guard !site.isSimpleSite else {
            onCompletion?(.success(.expiredWPComPlan))
            return
        }
        Task { @MainActor in
            do {
                let result = try await checkMinimumWooVersion(for: site)
                onCompletion?(.success(result))
            } catch {
                onCompletion?(.failure(error))
            }
        }
    }

    /// This function checks the default site's API version and then displays a warning
    /// if the site's WC version is not valid or the site is running on an expired plan.
    ///
    /// NOTE: When checking the default site's WC version, if 1) an error occurs or 2) the server response is invalid, WC version alert will *not* be displayed.
    ///
    func checkEligibilityForDefaultStore() {
        guard stores.isAuthenticated else {
            return
        }
        guard let site = stores.sessionManager.defaultSite, site.siteID != 0 else {
            DDLogWarn("⚠️ Cannot check WC version on default store — default siteID is nil or 0.")
            return
        }

        checkSiteEligibility(for: site) { [weak self] result in
            switch result {
            case .success(.invalidWCVersion):
                self?.displayWCVersionAlert()
            case .success(.expiredWPComPlan):
                self?.displayWPComPlanUpgradeAlert(for: site)
            default:
                break
            }
        }
    }
}


// MARK: - Private helpers
//
private extension RequirementsChecker {

    /// Display the WC version alert
    ///
    func displayWCVersionAlert() {
        let fancyAlert = FancyAlertViewController.makeWooUpgradeAlertController()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        baseViewController?.present(fancyAlert, animated: true)
    }

    func displayWPComPlanUpgradeAlert(for site: Site) {
        guard let baseViewController else {
            return
        }
        UIAlertController.presentExpiredWPComPlanAlert(from: baseViewController)
    }

    /// This function simply checks the provided site's API version. No warning will be displayed to the user.
    ///
    /// - parameter siteID: The SiteID to perform a version check on
    /// - parameter onCompletion: Closure to be executed upon completion with the result of the requirement check
    ///
    @MainActor
    func checkMinimumWooVersion(for site: Site) async throws -> RequirementCheckResult {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(retrieveSiteAPIAction(siteID: site.siteID) { result in
                switch result {
                case .success(let checkResult):
                    continuation.resume(returning: checkResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    /// Returns a `SettingAction.retrieveSiteAPI` action
    ///
    func retrieveSiteAPIAction(siteID: Int64, onCompletion: ((Result<RequirementCheckResult, Error>) -> Void)? = nil) -> SettingAction {
        return SettingAction.retrieveSiteAPI(siteID: siteID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let siteAPI):
                let saveTelemetryAvailabilityAction = AppSettingsAction.setTelemetryAvailability(siteID: siteID, isAvailable: siteAPI.telemetryIsAvailable)
                self.stores.dispatch(saveTelemetryAvailabilityAction)

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
}
