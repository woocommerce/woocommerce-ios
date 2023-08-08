import Foundation
import SwiftUI
import Yosemite
import Combine

/// ViewModel for the Upgrades View
/// Drives the site's available In-App Purchases plan upgrades
///
final class LegacyUpgradesViewModel: ObservableObject {

    @Published var entitledWpcomPlanIDs: Set<String>
    @Published var upgradeViewState: LegacyUpgradeViewState = .loading

    private let inAppPurchasesPlanManager: InAppPurchasesForWPComPlansProtocol
    private let siteID: Int64
    private let storePlanSynchronizer: StorePlanSynchronizing
    private let stores: StoresManager
    private let localPlans: [LegacyWooPlan] = [.loadHardcodedPlan()]
    private let analytics: Analytics

    private let notificationCenter: NotificationCenter = NotificationCenter.default
    private var applicationDidBecomeActiveObservationToken: NSObjectProtocol?

    private var cancellables: Set<AnyCancellable> = []

    init(siteID: Int64,
         inAppPurchasesPlanManager: InAppPurchasesForWPComPlansProtocol = InAppPurchasesForWPComPlansManager(),
         storePlanSynchronizer: StorePlanSynchronizing = ServiceLocator.storePlanSynchronizer,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.inAppPurchasesPlanManager = inAppPurchasesPlanManager
        self.storePlanSynchronizer = storePlanSynchronizer
        self.stores = stores
        self.analytics = analytics

        entitledWpcomPlanIDs = []

        observeViewStateAndTrackAnalytics()
        checkForSiteOwnership()
    }

    /// Sync wrapper for `fetchViewData`, so can be called directly from where this
    /// ViewModel is referenced, outside of the initializer
    ///
    func retryFetch() {
        Task {
            await fetchViewData()
        }
    }

    /// Retrieves all In-App Purchases WPCom plans
    ///
    @MainActor
    func fetchPlans() async {
        do {
            guard await inAppPurchasesPlanManager.inAppPurchasesAreSupported() else {
                upgradeViewState = .prePurchaseError(.inAppPurchasesNotSupported)
                return
            }

            async let wpcomPlans = inAppPurchasesPlanManager.fetchPlans()
            async let hardcodedPlanDataIsValid = checkHardcodedPlanDataValidity()

            try await loadUserEntitlements(for: wpcomPlans)
            guard entitledWpcomPlanIDs.isEmpty else {
                upgradeViewState = .prePurchaseError(.maximumSitesUpgraded)
                return
            }

            guard let plan = try await retrievePlanDetailsIfAvailable(.essentialMonthly,
                                                                      from: wpcomPlans,
                                                                      hardcodedPlanDataIsValid: hardcodedPlanDataIsValid)
            else {
                upgradeViewState = .prePurchaseError(.fetchError)
                return
            }
            upgradeViewState = .loaded(plan)
        } catch {
            DDLogError("fetchPlans \(error)")
            upgradeViewState = .prePurchaseError(.fetchError)
        }
    }

    /// Triggers the purchase of the specified In-App Purchases WPCom plans by the passed plan ID
    /// linked to the current site ID
    ///
    @MainActor
    func purchasePlan(with planID: String) async {
        analytics.track(event: .InAppPurchases.planUpgradePurchaseButtonTapped(planID))
        guard let wooWPComPlan = planCanBePurchasedFromCurrentState() else {
            return
        }

        upgradeViewState = .purchasing(wooWPComPlan)

        observeInAppPurchaseDrawerDismissal { [weak self] in
            /// The drawer gets dismissed when the IAP is cancelled too. That gets dealt with in the `do-catch`
            /// below, but this is usually received before the `.userCancelled`, so we need to wait a little
            /// before we try to advance to the waiting state.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                guard let self else { return }
                /// If the user cancelled, the state will be `.loaded(_)` by now, so we don't advance to waiting.
                /// Likewise, errors will have moved us to `.error(_)`, so we won't advance then either.
                if case .purchasing(_) = self.upgradeViewState {
                    self.upgradeViewState = .waiting(wooWPComPlan)
                }
            }
        }

        do {
            let result = try await inAppPurchasesPlanManager.purchasePlan(with: planID,
                                                                          for: siteID)
            stopObservingInAppPurchaseDrawerDismissal()
            switch result {
            case .userCancelled:
                upgradeViewState = .loaded(wooWPComPlan)
            case .success(.verified(_)):
                // refreshing the synchronizer removes the Upgrade Now banner by the time the flow is closed
                storePlanSynchronizer.reloadPlan()
                upgradeViewState = .completed(wooWPComPlan)
            default:
                // TODO: handle `.success(.unverified(_))` here... somehow
                return
            }
        } catch {
            DDLogError("purchasePlan \(error)")
            stopObservingInAppPurchaseDrawerDismissal()
            guard let recognisedError = error as? InAppPurchaseStore.Errors else {
                upgradeViewState = .purchaseUpgradeError(.unknown)
                return
            }

            switch recognisedError {
            case .unverifiedTransaction,
                    .transactionProductUnknown,
                    .inAppPurchasesNotSupported,
                    .inAppPurchaseProductPurchaseFailed,
                    .inAppPurchaseStoreKitFailed:
                upgradeViewState = .purchaseUpgradeError(.inAppPurchaseFailed(wooWPComPlan, recognisedError))
            case .transactionMissingAppAccountToken,
                    .appAccountTokenMissingSiteIdentifier,
                    .storefrontUnknown,
                    .transactionAlreadyAssociatedWithAnUpgrade:
                upgradeViewState = .purchaseUpgradeError(.planActivationFailed(recognisedError))
            }
        }
    }
}

// MARK: - Helpers
//
private extension LegacyUpgradesViewModel {
    /// Iterates through all available WPCom plans and checks whether the merchant is entitled to purchase them
    /// via In-App Purchases
    ///
    @MainActor
    func loadUserEntitlements(for plans: [WPComPlanProduct]) async {
        do {
            for wpcomPlan in plans {
                if try await inAppPurchasesPlanManager.userIsEntitledToPlan(with: wpcomPlan.id) {
                    self.entitledWpcomPlanIDs.insert(wpcomPlan.id)
                } else {
                    self.entitledWpcomPlanIDs.remove(wpcomPlan.id)
                }
            }
        } catch {
            DDLogError("loadEntitlements \(error)")
            upgradeViewState = .prePurchaseError(.entitlementsError)
        }
    }

    @MainActor
    /// Checks whether the current plan details being displayed to merchants are accurate
    /// by reaching the remote feature flag
    ///
    func checkHardcodedPlanDataValidity() async -> Bool {
        return await withCheckedContinuation { continuation in
            stores.dispatch(FeatureFlagAction.isRemoteFeatureFlagEnabled(
                .hardcodedPlanUpgradeDetailsMilestone1AreAccurate,
                defaultValue: true) { isEnabled in
                continuation.resume(returning: isEnabled)
            })
        }
    }

    @MainActor
    func fetchViewData() async {
        upgradeViewState = .loading
        await fetchPlans()
    }

    /// Checks whether a plan can be purchased from the current view state,
    /// in which case the `WooWPComPlan` object is returned
    ///
    func planCanBePurchasedFromCurrentState() -> WooWPComPlan? {
        switch upgradeViewState {
        case .loaded(let plan), .purchaseUpgradeError(.inAppPurchaseFailed(let plan, _)):
            return plan
        default:
            return nil
        }
    }

    /// Checks whether the current user is the site owner, as only the site owner can perform
    /// In-App Purchases upgrades, despite their site role
    ///
    func checkForSiteOwnership() {
        if let site = stores.sessionManager.defaultSite, !site.isSiteOwner {
            self.upgradeViewState = .prePurchaseError(.userNotAllowedToUpgrade)
        } else {
            Task {
                await fetchViewData()
            }
        }
    }
}

// MARK: - Notification observers
//
private extension LegacyUpgradesViewModel {
    /// Observes the `didBecomeActiveNotification` for one invocation of the notification.
    /// Using this in the scope of `purchasePlan` tells us when Apple's IAP view has completed.
    ///
    /// However, it can also be triggered by other actions, e.g. a phone call ending.
    ///
    /// One good example test is to start an IAP, then background the app and foreground it again
    /// before the IAP drawer is shown.  You'll see that this notification is received, even though the
    /// IAP drawer is then shown on top. Dismissing or completing the IAP will not then trigger this
    /// notification again.
    ///
    /// It's not perfect, but it's what we have.
    func observeInAppPurchaseDrawerDismissal(whenFired action: @escaping (() -> Void)) {
        applicationDidBecomeActiveObservationToken = notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                action()
                self?.stopObservingInAppPurchaseDrawerDismissal()
            }
    }

    func stopObservingInAppPurchaseDrawerDismissal() {
        if let token = applicationDidBecomeActiveObservationToken {
            notificationCenter.removeObserver(token)
        }
    }

    /// Retrieves a specific In-App Purchase WPCom plan from the available products
    ///
    func retrievePlanDetailsIfAvailable(_ type: AvailableInAppPurchasesWPComPlans,
                                                from wpcomPlans: [WPComPlanProduct],
                                                hardcodedPlanDataIsValid: Bool) -> WooWPComPlan? {
        guard let wpcomPlanProduct = wpcomPlans.first(where: { $0.id == type.rawValue }),
              let wooPlan = localPlans.first(where: { $0.id == wpcomPlanProduct.id }) else {
            return nil
        }
        return WooWPComPlan(wpComPlan: wpcomPlanProduct,
                            wooPlan: wooPlan,
                            hardcodedPlanDataIsValid: hardcodedPlanDataIsValid)
    }
}

// MARK: - Analytics observers, and track events
//
extension LegacyUpgradesViewModel {
    /// Observes the view state and tracks events when this changes
    ///
    private func observeViewStateAndTrackAnalytics() {
        $upgradeViewState.sink { [weak self] state in
            switch state {
            case .waiting:
                self?.analytics.track(.planUpgradeProcessingScreenLoaded)
            case .loaded:
                self?.analytics.track(.planUpgradeScreenLoaded)
            case .completed:
                self?.analytics.track(.planUpgradeCompletedScreenLoaded)
            case .prePurchaseError(let error):
                self?.analytics.track(event: .InAppPurchases.planUpgradePrePurchaseFailed(error: error))
            case .purchaseUpgradeError(let error):
                self?.analytics.track(event: .InAppPurchases.planUpgradePurchaseFailed(error: error.analyticErrorDetail))
            default:
                break
            }
        }
        .store(in: &cancellables)
    }

    func track(_ stat: WooAnalyticsStat) {
        analytics.track(stat)
    }

    func onDisappear() {
        guard let stepTracked = upgradeViewState.analyticsStep else {
            return
        }
        analytics.track(event: .InAppPurchases.planUpgradeScreenDismissed(step: stepTracked))
    }
}
