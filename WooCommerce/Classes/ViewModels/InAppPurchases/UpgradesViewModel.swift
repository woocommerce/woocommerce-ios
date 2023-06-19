import Foundation
import SwiftUI
import Yosemite

enum UpgradeViewState {
    case loading
    case loaded(WooWPComPlan)
    case waiting
    case completed
    case userNotAllowedToUpgrade
    case error(UpgradesError)
}

enum UpgradesError: Error {
    case purchaseError
    case fetchError
    case entitlementsError
    case inAppPurchasesNotSupported
    case maximumSitesUpgraded
}

/// ViewModel for the Upgrades View
/// Drives the site's available In-App Purchases plan upgrades
///
final class UpgradesViewModel: ObservableObject {

    private let inAppPurchasesPlanManager: InAppPurchasesForWPComPlansProtocol
    private let siteID: Int64
    private let stores: StoresManager

    @Published var entitledWpcomPlanIDs: Set<String>

    @Published var upgradeViewState: UpgradeViewState = .loading

    private let localPlans: [WooPlan]

    init(siteID: Int64,
         inAppPurchasesPlanManager: InAppPurchasesForWPComPlansProtocol = InAppPurchasesForWPComPlansManager(),
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.inAppPurchasesPlanManager = inAppPurchasesPlanManager
        self.stores = stores

        entitledWpcomPlanIDs = []

        if let essentialPlan = WooPlan() {
            self.localPlans = [essentialPlan]
        } else {
            self.localPlans = []
        }

        if let site = ServiceLocator.stores.sessionManager.defaultSite, !site.isSiteOwner {
            self.upgradeViewState = .userNotAllowedToUpgrade
        } else {
            Task {
                await fetchViewData()
            }
        }
    }

    @MainActor
    private func fetchViewData() async {
        upgradeViewState = .loading
        await fetchPlans()
    }

    /// Retrieves all In-App Purchases WPCom plans
    ///
    @MainActor
    func fetchPlans() async {
        do {
            guard await inAppPurchasesPlanManager.inAppPurchasesAreSupported() else {
                upgradeViewState = .error(.inAppPurchasesNotSupported)
                return
            }

            async let wpcomPlans = inAppPurchasesPlanManager.fetchPlans()
            async let hardcodedPlanDataIsValid = checkHardcodedPlanDataValidity()

            try await loadUserEntitlements(for: wpcomPlans)
            guard entitledWpcomPlanIDs.isEmpty else {
                upgradeViewState = .error(.maximumSitesUpgraded)
                return
            }

            guard let plan = try await retrievePlanDetailsIfAvailable(.essentialMonthly,
                                                                      from: wpcomPlans,
                                                                      hardcodedPlanDataIsValid: hardcodedPlanDataIsValid)
            else {
                upgradeViewState = .error(.fetchError)
                return
            }
            upgradeViewState = .loaded(plan)
        } catch {
            DDLogError("fetchPlans \(error)")
            upgradeViewState = .error(.fetchError)
        }
    }


    @MainActor
    private func checkHardcodedPlanDataValidity() async -> Bool {
        return await withCheckedContinuation { continuation in
            stores.dispatch(FeatureFlagAction.isRemoteFeatureFlagEnabled(
                .hardcodedPlanUpgradeDetailsMilestone1AreAccurate,
                defaultValue: true) { isEnabled in
                continuation.resume(returning: isEnabled)
            })
        }
    }

    /// Triggers the purchase of the specified In-App Purchases WPCom plans by the passed plan ID
    /// linked to the current site ID
    ///
    @MainActor
    func purchasePlan(with planID: String) async {
        do {
            upgradeViewState = .waiting
            let result = try await inAppPurchasesPlanManager.purchasePlan(with: planID,
                                                                          for: siteID)
            // TODO: handle `pending` here... somehow – requires research
            // TODO: handle `.success(.unverified(_))` here... somehow
            guard case .success(.verified(_)) = result else {
                await fetchViewData()
                return
            }
            upgradeViewState = .completed
        } catch {
            DDLogError("purchasePlan \(error)")
            upgradeViewState = .error(UpgradesError.purchaseError)
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

private extension UpgradesViewModel {
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
            upgradeViewState = .error(UpgradesError.entitlementsError)
        }
    }
}

extension UpgradesViewModel {
    enum AvailableInAppPurchasesWPComPlans: String {
        case essentialMonthly = "debug.woocommerce.express.essential.monthly"
    }
}

struct WooWPComPlan {
    let wpComPlan: WPComPlanProduct
    let wooPlan: WooPlan
    let hardcodedPlanDataIsValid: Bool
}
