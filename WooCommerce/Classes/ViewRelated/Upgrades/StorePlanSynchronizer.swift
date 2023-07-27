import Foundation
import Yosemite
import Combine
import Experiments

/// Type that fetches and shares a `WPCom` store plan(subscription).
/// The plan is stored on memory and not on the Storage Layer because this only relates to `WPCom` stores.
///
final class StorePlanSynchronizer: ObservableObject {

    /// Dependency state.
    ///
    enum PlanState: Equatable {
        case notLoaded
        case loading
        case loaded(WPComSitePlan)
        case failed
        case unavailable
        case expired
    }

    /// Current synced plan.
    ///
    @Published private(set) var planState = PlanState.notLoaded

    /// Current logged-in site. `Nil` if not logged-in.
    ///
    private(set) var site: Site?

    /// Stores manager.
    ///
    private let stores: StoresManager

    /// Handles local notifications for free trial plan expiration
    ///
    private let localNotificationScheduler: LocalNotificationScheduler

    /// Time zone used to scheduling local notifications.
    ///
    private let timeZone: TimeZone

    /// Observable subscription store.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    private let inAppPurchaseManager: InAppPurchasesForWPComPlansProtocol
    private let featureFlagService: FeatureFlagService

    init(stores: StoresManager = ServiceLocator.stores,
         timeZone: TimeZone = .current,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
         inAppPurchaseManager: InAppPurchasesForWPComPlansProtocol = InAppPurchasesForWPComPlansManager(),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.localNotificationScheduler = .init(pushNotesManager: pushNotesManager, stores: stores)
        self.timeZone = timeZone
        self.inAppPurchaseManager = inAppPurchaseManager
        self.featureFlagService = featureFlagService

        stores.site.sink { [weak self] site in
            guard let self else { return }
            self.site = site
            self.reloadPlan()
        }
        .store(in: &subscriptions)
    }

    /// Loads the plan from network
    ///
    func reloadPlan() {
        // If there is no logged-in site set the state to `.notLoaded`
        guard let site else {
            planState = .notLoaded
            return
        }

        // If the site is not a WPCom store set the state to `.unavailable`
        guard site.isWordPressComStore else {
            planState = .unavailable
            return
        }

        // Do not fetch the plan if the plan it is already being loaded.
        guard planState != .loading else { return }

        planState = .loading
            let action = PaymentAction.loadSiteCurrentPlan(siteID: site.siteID) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let plan):
                self.planState = .loaded(plan)
                self.scheduleOrCancelNotificationsIfNeeded(for: plan)
            case .failure(LoadSiteCurrentPlanError.noCurrentPlan):
                // Since this is a WPCom store, if it has no plan its plan must have expired or been cancelled.
                // Generally, expiry is `.success(plan)` with a plan expiry date in the past, but in some cases, we just
                // don't get any plans marked as `current` in the plans response.
                self.planState = .expired
            case .failure(let error):
                self.planState = .failed
                DDLogError("⛔️ Error synchronizing WPCom plan: \(error)")
            }
        }
        stores.dispatch(action)
    }
}

// MARK: - Local notifications about trial plan expiration
//
private extension StorePlanSynchronizer {
    func scheduleOrCancelNotificationsIfNeeded(for plan: WPComSitePlan) {
        guard let siteID = site?.siteID else {
            return
        }
        guard plan.isFreeTrial else {
            /// cancels any scheduled notifications
            Task {
                await cancelFreeTrialExpirationNotifications(siteID: siteID)
            }
            return
        }

        if let subscribedDate = plan.subscribedDate {
            // Schedule notification only if the Free trial is subscribed less than 6 hrs ago
            if Date().timeIntervalSince(subscribedDate) < Constants.sixHoursTimeInterval {
                let scenario = LocalNotification.Scenario.sixHoursAfterFreeTrialSubscribed(siteID: siteID)
                schedulePostSubscriptionNotification(scenario: scenario,
                                                     timeAfterSubscription: Constants.sixHoursTimeInterval,
                                                     subscribedDate: subscribedDate)
            }

            if featureFlagService.isFeatureFlagEnabled(.freeTrialSurvey24hAfterFreeTrialSubscribed) {
                // Schedule notification only if the Free trial is subscribed less than 24 hrs ago
                if Date().timeIntervalSince(subscribedDate) < Constants.oneDayTimeInterval {
                    let scenario = LocalNotification.Scenario.freeTrialSurvey24hAfterFreeTrialSubscribed(siteID: siteID)
                    schedulePostSubscriptionNotification(scenario: scenario,
                                                         timeAfterSubscription: Constants.oneDayTimeInterval,
                                                         subscribedDate: subscribedDate)
                }
            } else { // TODO: 10266 Safely remove
                // Schedule notification only if the Free trial is subscribed less than 24 hrs ago
                if Date().timeIntervalSince(subscribedDate) < Constants.oneDayTimeInterval {
                    let scenario = LocalNotification.Scenario.twentyFourHoursAfterFreeTrialSubscribed(siteID: siteID)
                    schedulePostSubscriptionNotification(scenario: scenario,
                                                         timeAfterSubscription: Constants.oneDayTimeInterval,
                                                         subscribedDate: subscribedDate)
                }
            }
        }
    }

    func cancelFreeTrialExpirationNotifications(siteID: Int64) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.localNotificationScheduler.cancel(scenario: .oneDayAfterFreeTrialExpires(siteID: siteID))
            }
            group.addTask { [weak self] in
                await self?.localNotificationScheduler.cancel(scenario: .oneDayBeforeFreeTrialExpires(
                    siteID: siteID,
                    expiryDate: Date() // placeholder date, irrelevant to the notification identifier
                ))
            }
            group.addTask { [weak self] in
                await self?.localNotificationScheduler.cancel(scenario: .sixHoursAfterFreeTrialSubscribed(siteID: siteID))
            }
            group.addTask { [weak self] in
                await self?.localNotificationScheduler.cancel(scenario: .twentyFourHoursAfterFreeTrialSubscribed(siteID: siteID))
            }
            group.addTask { [weak self] in
                await self?.localNotificationScheduler.cancel(scenario: .freeTrialSurvey24hAfterFreeTrialSubscribed(siteID: siteID))
            }
        }
    }

    func schedulePostSubscriptionNotification(scenario: LocalNotification.Scenario,
                                              timeAfterSubscription: TimeInterval,
                                              subscribedDate: Date) {
        /// Scheduled after subscribed date
        let triggerDateComponents = subscribedDate.addingTimeInterval(timeAfterSubscription).dateAndTimeComponents()
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        Task {
            let iapAvailable = await inAppPurchaseManager.inAppPurchasesAreSupported()
            let notification = LocalNotification(scenario: scenario,
                                                 userInfo: [LocalNotification.UserInfoKey.isIAPAvailable: iapAvailable])
            await localNotificationScheduler.schedule(notification: notification,
                                                      trigger: trigger,
                                                      remoteFeatureFlag: nil,
                                                      shouldSkipIfScheduled: true)
        }
    }
}

private extension StorePlanSynchronizer {
    enum Constants {
        static let sixHoursTimeInterval: TimeInterval = 21600
        static let oneDayTimeInterval: TimeInterval = 86400
    }
}
