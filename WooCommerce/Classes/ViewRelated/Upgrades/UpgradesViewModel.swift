import Foundation
import Yosemite

/// ViewModel for the Upgrades View
///
final class UpgradesViewModel: ObservableObject {

    /// Dependency state.
    ///
    enum PlanState: Equatable {
        case notLoaded
        case loading
        case loaded(WPComSitePlan)
    }

    /// Indicates if the view should should a redacted state.
    ///
    var showLoadingIndicator: Bool {
        planState == .loading
    }

    /// Current store plan.
    ///
    private(set) var planName = ""

    /// Current store plan details information.
    ///
    private(set) var planInfo = ""

    /// Defines if the view should show the "Upgrade Now" button.
    ///
    private(set) var shouldShowUpgradeButton = false

    /// Defines if the view should show the "Cancel Free Trial"  button.
    ///
    private(set) var shouldShowCancelTrialButton = false

    /// Current dependency state.
    ///
    @Published private var planState = PlanState.notLoaded

    /// Current site id.
    ///
    private let siteID: Int64

    /// Stores manager.
    ///
    private let stores: StoresManager

    /// Analytics provider.
    ///
    private let analytics: Analytics

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
    }

    /// Loads the plan from network if needed.
    ///
    func loadPlan() {
        guard planState == .notLoaded else { return }

        planState = .loading
        let action = PaymentAction.loadSiteCurrentPlan(siteID: siteID) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let plan):
                self.planState = .loaded(plan)
                self.updateViewProperties(from: plan)
            case .failure(let error):
                self.planState = .notLoaded
                DDLogError("⛔️ Unable to fetch site's plan: \(error)")
                // TODO: Abort flow and inform user
            }
        }
        stores.dispatch(action)
    }
}

// MARK: Helpers
private extension UpgradesViewModel {
    func updateViewProperties(from plan: WPComSitePlan) {
        planName = Self.getPlanName(from: plan)
        planInfo = Self.getPlanInfo(from: plan)
        shouldShowUpgradeButton = Self.getUpgradeNowButtonVisibility(from: plan)
    }

    /// Removes any occurrences of `WordPress.com` from the site's name.
    /// Free Trial's have an special handling!
    ///
    static func getPlanName(from plan: WPComSitePlan) -> String {
        // Handle the "Free trial" case specially.
        if plan.isFreeTrial {
            if daysLeft(for: plan) > 0 {
                return Localization.freeTrial
            } else {
                return Localization.trialEnded
            }
        }

        // For non-free trials plans  remove any mention to WPCom.
        let toRemove = "WordPress.com"
        let sanitizedName = plan.name.replacingOccurrences(of: toRemove, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitizedName
    }

    /// Returns a plan specific details information.
    ///
    static func getPlanInfo(from plan: WPComSitePlan) -> String {
        let daysLeft = daysLeft(for: plan)
        let planDuration = planDurationInDays(for: plan)

        if plan.isFreeTrial {
            if daysLeft > 0 {
                return Localization.freeTrialPlanInfo(planDuration: planDuration, daysLeft: daysLeft)
            } else {
                return Localization.trialEndedInfo
            }
        }

        let planName = getPlanName(from: plan)
        guard let expireDate = plan.expiryDate else {
            return ""
        }

        let expireText = DateFormatter.mediumLengthLocalizedDateFormatter.string(from: expireDate)
        return Localization.planInfo(planName: planName, expirationDate: expireText)
    }

    /// Only allow to upgrade the plan if we are on a free trial.
    ///
    static func getUpgradeNowButtonVisibility(from plan: WPComSitePlan) -> Bool {
        plan.isFreeTrial
    }

    /// Returns a site plan duration in days.
    ///
    static func planDurationInDays(for plan: WPComSitePlan) -> Int {
        // Normalize dates in the same timezone.
        guard let subscribedDate = plan.subscribedDate?.startOfDay(timezone: .current),
              let expiryDate = plan.expiryDate?.startOfDay(timezone: .current) else {
            return 0
        }

        let duration = Calendar.current.dateComponents([.day], from: subscribedDate, to: expiryDate).day ?? 0
        return duration
    }

    /// Returns how many days site  plan has left.
    ///
    static func daysLeft(for plan: WPComSitePlan) -> Int {
        // Normalize dates in the same timezone.
        let today = Date().startOfDay(timezone: .current)
        guard let expiryDate = plan.expiryDate?.startOfDay(timezone: .current) else {
            return 0
        }

        let daysLeft = Calendar.current.dateComponents([.day], from: today, to: expiryDate).day ?? 0
        return daysLeft
    }
}

// MARK: Definitions
private extension UpgradesViewModel {
    enum Localization {
        static let freeTrial = NSLocalizedString("Free Trial", comment: "Plan name for an active free trial")
        static let trialEnded = NSLocalizedString("Trial ended", comment: "Plan name for an expired free trial")
        static let trialEndedInfo = NSLocalizedString("Your free trial has ended and have limited access to all the features. Subscribe to eCommerce now.",
                                                      comment: "Info details for an expired free trial")
        static func freeTrialPlanInfo(planDuration: Int, daysLeft: Int) -> String {
            let format = NSLocalizedString("You are in the %1d-day free trial. The free trial will end in %2d days. " +
                                           "Upgrade to unlock new features and keep your store running.",
                                           comment: "Reads like: You are in the 14-day free trial. The free trial will end in 5 days. " +
                                           "Upgrade to unlock new features and keep your store running.")
            return String.localizedStringWithFormat(format, planDuration, daysLeft)
        }

        static func planInfo(planName: String, expirationDate: String) -> String {
            let format = NSLocalizedString("You are a %1@ subscriber! You have access to all our features until %2@.",
                                           comment: "Reads like: You are a eCommerce subscriber! You have access to all our features until Nov 28, 2023.")
            return String.localizedStringWithFormat(format, planName, expirationDate)
        }
    }
}
