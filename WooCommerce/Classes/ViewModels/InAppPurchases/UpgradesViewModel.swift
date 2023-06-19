import Foundation
import SwiftUI
import Yosemite

enum UpgradeViewState {
    case normal
    case loading
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
}

/// ViewModel for the Upgrades View
/// Drives the site's available In-App Purchases plan upgrades
///
final class UpgradesViewModel: ObservableObject {

    private let inAppPurchasesPlanManager: InAppPurchasesForWPComPlansProtocol
    private let siteID: Int64

    @Published var wpcomPlans: [WPComPlanProduct]
    @Published var entitledWpcomPlanIDs: Set<String>
    @Published var upgradePlan: WooWPComPlan? = nil

    @Published var upgradeViewState: UpgradeViewState = .loading

    private let localPlans: [WooPlan]

    init(siteID: Int64, inAppPurchasesPlanManager: InAppPurchasesForWPComPlansProtocol = InAppPurchasesForWPComPlansManager()) {
        self.siteID = siteID
        self.inAppPurchasesPlanManager = inAppPurchasesPlanManager

        wpcomPlans = []
        entitledWpcomPlanIDs = []

        if let essentialPlan = WooPlan() {
            self.localPlans = [essentialPlan]
        } else {
            self.localPlans = []
        }

        if let site = ServiceLocator.stores.sessionManager.defaultSite, !site.isSiteOwner {
            self.upgradeViewState = .userNotAllowedToUpgrade
        } else {
            Task { [weak self] in
                await self?.fetchPlans()
            }
        }
    }

    /// Retrieves all In-App Purchases WPCom plans
    ///
    @MainActor
    func fetchPlans() async {
        do {
            guard await inAppPurchasesPlanManager.inAppPurchasesAreSupported() else {
                DDLogError("IAP not supported")
                return
            }

            self.wpcomPlans = try await inAppPurchasesPlanManager.fetchPlans()

            await loadUserEntitlements()
            if entitledWpcomPlanIDs.isEmpty {
                self.upgradePlan = retrievePlanDetailsIfAvailable(.essentialMonthly)
            }
            upgradeViewState = .normal
        } catch {
            DDLogError("fetchPlans \(error)")
            upgradeViewState = .error(UpgradesError.fetchError)
        }
    }

    /// Triggers the purchase of the specified In-App Purchases WPCom plans by the passed plan ID
    /// linked to the current site ID
    ///
    @MainActor
    func purchasePlan(with planID: String) async {
        do {
            upgradeViewState = .waiting
            let _ = try await inAppPurchasesPlanManager.purchasePlan(with: planID, for: self.siteID)
            upgradeViewState = .completed
        } catch {
            DDLogError("purchasePlan \(error)")
            upgradeViewState = .error(UpgradesError.purchaseError)
        }
    }

    /// Retrieves a specific In-App Purchase WPCom plan from the available products
    ///
    func retrievePlanDetailsIfAvailable(_ type: AvailableInAppPurchasesWPComPlans) -> WooWPComPlan? {
        let match = type.rawValue
        guard let wpcomPlanProduct = wpcomPlans.first(where: { $0.id == match }) else {
            return nil
        }
        let wooPlan = localPlans.first { $0.id == wpcomPlanProduct.id }
        return WooWPComPlan(wpComPlan: wpcomPlanProduct, wooPlan: wooPlan)
    }
}

private extension UpgradesViewModel {
    /// Iterates through all available WPCom plans and checks whether the merchant is entitled to purchase them
    /// via In-App Purchases
    ///
    @MainActor
    func loadUserEntitlements() async {
        do {
            for wpcomPlan in self.wpcomPlans {
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
    let wooPlan: WooPlan?
}
