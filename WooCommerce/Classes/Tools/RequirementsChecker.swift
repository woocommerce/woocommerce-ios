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
class RequirementsChecker {

    /// Private: NO-OP
    ///
    private init() { }

    /// This function checks the default site's API version and then displays a warning if the
    /// site's WC version is not valid.
    ///
    /// If the site is WPCom, the site plan is fetched first to determine if the site is running on an expired plan.
    ///
    static func checkSiteEligibility(for siteID: Int64, onCompletion: ((Result<RequirementCheckResult, Error>) -> Void)? = nil) {
        switch siteID {
        case WooConstants.placeholderStoreID:
            // Skips site plan check for non-WPCom site
            checkMinimumWooVersion(for: siteID, onCompletion: onCompletion)
        default:
            checkWPComSitePlan(for: siteID, onCompletion: onCompletion)
        }
    }

    /// This function checks the default site's API version and then displays a warning
    /// if the site's WC version is not valid or the site is running on an expired plan.
    ///
    /// NOTE: When checking the default site's WC version, if 1) an error occurs or 2) the server response is invalid, WC version alert will *not* be displayed.
    ///
    static func checkEligibilityForDefaultStore() {
        guard ServiceLocator.stores.isAuthenticated else {
            return
        }
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID, siteID != 0 else {
            DDLogWarn("⚠️ Cannot check WC version on default store — default siteID is nil or 0.")
            return
        }

        checkSiteEligibility(for: siteID) { result in
            switch result {
            case .success(.invalidWCVersion):
                displayWCVersionAlert()
            case .success(.expiredWPComPlan):
                displayWPComPlanUpgradeAlert(siteID: siteID)
            default:
                break
            }
        }
    }
}


// MARK: - Private helpers
//
private extension RequirementsChecker {
    static func checkWPComSitePlan(for siteID: Int64, onCompletion: ((Result<RequirementCheckResult, Error>) -> Void)? = nil) {
        let action = PaymentAction.loadSiteCurrentPlan(siteID: siteID) { result in
            switch result {
            case .success(let plan):
                // Normalize dates in the same timezone.
                let today = Date().startOfDay(timezone: .current)
                guard plan.isFreeTrial, let expiryDate = plan.expiryDate?.startOfDay(timezone: .current) else {
                    return checkMinimumWooVersion(for: siteID, onCompletion: onCompletion)
                }
                let daysLeft = Calendar.current.dateComponents([.day], from: today, to: expiryDate).day ?? 0
                if daysLeft <= 0 {
                    onCompletion?(.success(.expiredWPComPlan))
                } else {
                    checkMinimumWooVersion(for: siteID, onCompletion: onCompletion)
                }
            case .failure(LoadSiteCurrentPlanError.noCurrentPlan):
                // Since this is a WPCom store, if it has no plan its plan must have expired or been cancelled.
                // Generally, expiry is `.success(plan)` with a plan expiry date in the past, but in some cases, we just
                // don't get any plans marked as `current` in the plans response.
                onCompletion?(.success(.expiredWPComPlan))
            case .failure(let error):
                onCompletion?(.failure(error))
                DDLogError("⛔️ Error synchronizing WPCom plan: \(error)")
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Display the WC version alert
    ///
    static func displayWCVersionAlert() {
        let fancyAlert = FancyAlertViewController.makeWooUpgradeAlertController()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        AppDelegate.shared.tabBarController?.present(fancyAlert, animated: true)
    }

    static func displayWPComPlanUpgradeAlert(siteID: Int64) {
        let alertController = UIAlertController(title: Localization.expiredPlan,
                                                message: Localization.expiredPlanDescription,
                                                preferredStyle: .alert)
        let action = UIAlertAction(title: Localization.upgrade, style: .default) { _ in
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.freeTrialInAppPurchasesUpgradeM1) {
                let upgradesController = UINavigationController(rootViewController: UpgradesHostingController(siteID: siteID))
                AppDelegate.shared.tabBarController?.present(upgradesController, animated: true)
            } else {
                let controller = UpgradePlanCoordinatingController(siteID: siteID, source: .expiredTrialPlanAlert)
                AppDelegate.shared.tabBarController?.present(controller, animated: true)
            }
        }
        alertController.addAction(action)
        AppDelegate.shared.tabBarController?.present(alertController, animated: true)
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

    /// Returns a `SettingAction.retrieveSiteAPI` action
    ///
    static func retrieveSiteAPIAction(siteID: Int64, onCompletion: ((Result<RequirementCheckResult, Error>) -> Void)? = nil) -> SettingAction {
        return SettingAction.retrieveSiteAPI(siteID: siteID) { result in
            switch result {
            case .success(let siteAPI):
                let saveTelemetryAvailabilityAction = AppSettingsAction.setTelemetryAvailability(siteID: siteID, isAvailable: siteAPI.telemetryIsAvailable)
                ServiceLocator.stores.dispatch(saveTelemetryAvailabilityAction)

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

private extension RequirementsChecker {
    enum Localization {
        static let expiredPlan = NSLocalizedString("Site plan expired", comment: "Title of the expired WPCom plan alert")
        static let expiredPlanDescription = NSLocalizedString(
            "We have paused your store, but you can continue by picking a plan that suits you best.",
            comment: "Message on the expired WPCom plan alert"
        )
        static let upgrade = NSLocalizedString("Upgrade", comment: "Button to upgrade a WPCom plan on the expired WPCom plan alert")
    }
}
