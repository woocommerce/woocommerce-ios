import Foundation
import SwiftUI
import Yosemite
import Combine
import protocol WooFoundation.Analytics

/// ViewModel for the Upgrades View
/// Drives the site's available In-App Purchases plan upgrades
///
final class UpgradesViewModel: ObservableObject {

    @Published var upgradeViewState: UpgradeViewState = .loading

    @Published var isPurchasing: Bool = false

    private let inAppPurchasesPlanManager: InAppPurchasesForWPComPlansProtocol
    private let siteID: Int64
    private let storePlanSynchronizer: StorePlanSynchronizing
    private let stores: StoresManager
    private let localPlans: [WooPlan] = WooPlan.loadM2HardcodedPlans()
    private let analytics: Analytics

    private let notificationCenter: NotificationCenter = NotificationCenter.default
    private var applicationDidBecomeActiveObservationToken: NSObjectProtocol?

    private var cancellables: Set<AnyCancellable> = []

    private var plans: [WooWPComPlan] = []

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

        observeViewStateAndTrackAnalytics()
    }

    /// Sync wrapper for `fetchViewData`, so can be called directly from where this
    /// ViewModel is referenced, outside of the initializer
    ///
    @MainActor
    func retryFetch() {
        Task {
            await fetchViewData()
        }
    }

    /// Sets up the view – validates whether they are eligible to upgrade and shows a plan
    ///
    @MainActor
    func prepareViewModel() async {
        do {
            guard let site = stores.sessionManager.defaultSite else {
                throw PrePurchaseError.fetchError
            }

            guard site.isSiteOwner else {
                throw PrePurchaseError.userNotAllowedToUpgrade
            }

            guard await inAppPurchasesPlanManager.inAppPurchasesAreSupported() else {
                throw PrePurchaseError.inAppPurchasesNotSupported
            }

            async let wpcomPlans = inAppPurchasesPlanManager.fetchPlans()
            async let hardcodedPlanDataIsValid = checkHardcodedPlanDataValidity()

            guard try await hasNoActiveInAppPurchases(for: wpcomPlans) else {
                throw PrePurchaseError.maximumSitesUpgraded
            }

            plans = try await retrievePlanDetailsIfAvailable([.essentialMonthly, .essentialYearly, .performanceMonthly, .performanceYearly],
                                                                 from: wpcomPlans,
                                                                 hardcodedPlanDataIsValid: hardcodedPlanDataIsValid)
            guard plans.count > 0 else {
                throw PrePurchaseError.fetchError
            }
            upgradeViewState = .loaded(plans)
        } catch let prePurchaseError as PrePurchaseError {
            DDLogError("prePurchaseError \(prePurchaseError)")
            upgradeViewState = .prePurchaseError(prePurchaseError)
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
        isPurchasing = true
        defer {
            isPurchasing = false
        }

        analytics.track(event: .InAppPurchases.planUpgradePurchaseButtonTapped(planID))
        guard let wooWPComPlan = planCanBePurchasedFromCurrentState(with: planID) else {
            return
        }

        observeInAppPurchaseDrawerDismissal { [weak self] in
            /// The drawer gets dismissed when the IAP is cancelled too. That gets dealt with in the `do-catch`
            /// below, but this is usually received before the `.userCancelled`, so we need to wait a little
            /// before we try to advance to the waiting state.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                guard let self else { return }
                /// If the user cancelled, we don't advance to waiting, just stay on the plans screen.
                /// If the user reached an error state, we will have moved to `.error(_)`, so we should not advance to waiting.
                /// In both the above cases, `isPurchasing` will have moved back to false in the defer block
                if self.isPurchasing {
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
                /// `no-op` – if the user cancels, we remain in the `loaded` state.
                return
            case .success(.verified):
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
private extension UpgradesViewModel {
    /// Iterates through all available WPCom plans and checks whether the merchant is entitled to purchase them
    /// via In-App Purchases
    ///
    func hasNoActiveInAppPurchases(for plans: [WPComPlanProduct]) async throws -> Bool {
        for plan in plans {
            do {
                if try await inAppPurchasesPlanManager.userIsEntitledToPlan(with: plan.id) {
                    return false
                }
            } catch {
                DDLogError("There was an error when loading entitlements: \(error)")
                throw PrePurchaseError.entitlementsError
            }
        }
        return true
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
        await prepareViewModel()
    }

    /// Checks whether a plan can be purchased from the current view state,
    /// in which case the `WooWPComPlan` object is returned
    ///
    func planCanBePurchasedFromCurrentState(with planID: String) -> WooWPComPlan? {
        switch upgradeViewState {
        case .loaded(let plans):
            return plans.first(where: { $0.wpComPlan.id == planID })
        case .purchaseUpgradeError(.inAppPurchaseFailed(let plan, _)):
            return plan
        default:
            return nil
        }
    }
}

// MARK: - Notification observers
//
private extension UpgradesViewModel {
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
    func retrievePlanDetailsIfAvailable(_ types: [AvailableInAppPurchasesWPComPlans],
                                        from wpcomPlans: [WPComPlanProduct],
                                        hardcodedPlanDataIsValid: Bool) -> [WooWPComPlan] {
        let plans: [WooWPComPlan] = types.map { type in
            guard let wpcomPlanProduct = wpcomPlans.first(where: { $0.id == type.rawValue }),
                  let wooPlan = localPlans.first(where: { $0.id == wpcomPlanProduct.id }) else {
                return nil
            }
            return WooWPComPlan(wpComPlan: wpcomPlanProduct,
                                wooPlan: wooPlan,
                                hardcodedPlanDataIsValid: hardcodedPlanDataIsValid)
        }.compactMap { $0 }

        return plans
    }
}

// MARK: - Analytics observers, and track events
//
extension UpgradesViewModel {
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
