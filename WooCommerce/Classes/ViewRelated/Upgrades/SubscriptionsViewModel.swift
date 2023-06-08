import Foundation
import Yosemite
import Combine
import protocol Experiments.FeatureFlagService

/// ViewModel for the Subscriptions View
/// Drives the site's plan subscription
///
final class SubscriptionsViewModel: ObservableObject {

    /// Indicates if the view should show an error notice.
    ///
    var errorNotice: Notice? = nil

    /// Current store plan.
    ///
    private(set) var planName = ""

    /// Current store plan details information.
    ///
    private(set) var planInfo = ""

    /// Current store plan details information.
    ///
    private(set) var planDaysLeft = ""

    /// Defines if the view should show the Full Plan features.
    ///
    private(set) var shouldShowFreeTrialFeatures = false

    /// Defines if the view should show the "Cancel Free Trial"  button.
    ///
    private(set) var shouldShowCancelTrialButton = false

    /// Indicates if the view should should a redacted state.
    ///
    private(set) var showLoadingIndicator = false

    /// Holds a reference to the free trial features.
    ///
    let freeTrialFeatures = FreeTrialFeatures.features

    /// Observable subscription store.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    /// Stores manager.
    ///
    private let stores: StoresManager

    /// Shared store plan synchronizer.
    ///
    private let storePlanSynchronizer: StorePlanSynchronizer

    /// Analytics provider.
    ///
    private let analytics: Analytics

    /// Feature flag service.
    ///
    private let featureFlagService: FeatureFlagService

    init(stores: StoresManager = ServiceLocator.stores,
         storePlanSynchronizer: StorePlanSynchronizer = ServiceLocator.storePlanSynchronizer,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.storePlanSynchronizer = storePlanSynchronizer
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        observePlan()
    }

    /// Loads the plan from network.
    ///
    func loadPlan() {
        storePlanSynchronizer.reloadPlan()
    }
}

// MARK: Helpers
private extension SubscriptionsViewModel {
    /// Observes and reacts to plan changes
    ///
    func observePlan() {
        storePlanSynchronizer.$planState.sink { [weak self] planState in
            guard let self else { return }
            switch planState {
            case .loading, .notLoaded:
                self.updateLoadingViewProperties()
            case .loaded(let plan):
                self.updateViewProperties(from: plan)
            case .failed, .unavailable:
                self.updateFailedViewProperties()
            }
            self.objectWillChange.send()
        }
        .store(in: &subscriptions)
    }

    func updateViewProperties(from plan: WPComSitePlan) {
        planName = getPlanName(from: plan)
        planInfo = getPlanInfo(from: plan)
        planDaysLeft = daysLeft(for: plan).formatted()
        errorNotice = nil
        showLoadingIndicator = false
        shouldShowFreeTrialFeatures = plan.isFreeTrial
    }

    func updateLoadingViewProperties() {
        planName = ""
        planInfo = ""
        errorNotice = nil
        showLoadingIndicator = true
        shouldShowFreeTrialFeatures = false
    }

    func updateFailedViewProperties() {
        planName = ""
        planInfo = ""
        errorNotice = createErrorNotice()
        showLoadingIndicator = false
        shouldShowFreeTrialFeatures = false
    }

    /// Removes any occurrences of `WordPress.com` from the site's name.
    /// Free Trial's have an special handling!
    ///
    private func getPlanName(from plan: WPComSitePlan) -> String {
        let daysLeft = daysLeft(for: plan)
        if plan.isFreeTrial, daysLeft <= 0 {
            return Localization.trialEnded
        }

        let sanitizedName = WPComPlanNameSanitizer.getPlanName(from: plan)
        if daysLeft > 0 {
            return sanitizedName
        } else {
            return Localization.planEndedName(name: sanitizedName)
        }
    }

    /// Returns a plan specific details information.
    ///
    private func getPlanInfo(from plan: WPComSitePlan) -> String {
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

        guard daysLeft > 0 else {
            return Localization.planEndedInfo
        }

        let expireText = DateFormatter.mediumLengthLocalizedDateFormatter.string(from: expireDate)
        return Localization.planInfo(planName: planName, expirationDate: expireText)
    }

    /// Returns a site plan duration in days.
    ///
    private func planDurationInDays(for plan: WPComSitePlan) -> Int {
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
    private func daysLeft(for plan: WPComSitePlan) -> Int {
        // Normalize dates in the same timezone.
        let today = Date().startOfDay(timezone: .current)
        guard let expiryDate = plan.expiryDate?.startOfDay(timezone: .current) else {
            return 0
        }

        let daysLeft = Calendar.current.dateComponents([.day], from: today, to: expiryDate).day ?? 0
        return daysLeft
    }

    /// Creates an error notice that allows to retry fetching a plan.
    ///
    private func createErrorNotice() -> Notice {
        .init(title: Localization.fetchErrorNotice, feedbackType: .error, actionTitle: Localization.retry) { [weak self] in
             self?.loadPlan()
        }
    }
}

// MARK: Definitions
private extension SubscriptionsViewModel {
    enum Localization {
        static let trialEnded = NSLocalizedString("Trial ended", comment: "Plan name for an expired free trial")
        static let trialEndedInfo = NSLocalizedString("Your free trial has ended and you have limited access to all the features. " +
                                                      "Subscribe to Woo Express Performance Plan now.",
                                                      comment: "Info details for an expired free trial")
        static let planEndedInfo = NSLocalizedString("Your subscription has ended and you have limited access to all the features.",
                                                     comment: "Info details for an expired free trial")
        static let fetchErrorNotice = NSLocalizedString("There was an error fetching your plan details, please try again later.",
                                                        comment: "Error shown when failing to fetch the plan details in the upgrades view.")
        static let retry = NSLocalizedString("Retry", comment: "Retry button on the error notice for the upgrade view")

        static func planEndedName(name: String) -> String {
            let format = NSLocalizedString("%@ ended", comment: "Reads like: eCommerce ended")
            return String.localizedStringWithFormat(format, name)
        }

        static func freeTrialPlanInfo(planDuration: Int, daysLeft: Int) -> String {
            let format = NSLocalizedString("You are in the %1$d-day free trial. The free trial will end in %2$d days. ",
                                           comment: "Reads like: You are in the 14-day free trial. The free trial will end in 5 days. " +
                                           "Upgrade to unlock new features and keep your store running.")
            return String.localizedStringWithFormat(format, planDuration, daysLeft)
        }

        static func planInfo(planName: String, expirationDate: String) -> String {
            let format = NSLocalizedString("You are subscribed to the %1@ plan! You have access to all our features until %2@.",
                                           comment: "Reads like: You are subscribed to the eCommerce plan! " +
                                                    "You have access to all our features until Nov 28, 2023.")
            return String.localizedStringWithFormat(format, planName, expirationDate)
        }
    }
}
