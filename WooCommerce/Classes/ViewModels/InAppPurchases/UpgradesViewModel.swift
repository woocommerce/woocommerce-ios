import Foundation
import SwiftUI
import Yosemite

/// ViewModel for the Upgrades View
/// Drives the site's available In-App Purchases plan upgrades
///
final class UpgradesViewModel: ObservableObject {

    private let inAppPurchasesPlanManager: InAppPurchasesForWPComPlansProtocol
    private let siteID: Int64
    private(set) var userIsAdministrator: Bool

    @Published var wpcomPlans: [WPComPlanProduct]
    @Published var entitledWpcomPlanIDs: Set<String>

    let plan: WooPlan? = WooPlan()

    init(siteID: Int64, inAppPurchasesPlanManager: InAppPurchasesForWPComPlansProtocol = InAppPurchasesForWPComPlansManager()) {
        self.siteID = siteID
        self.inAppPurchasesPlanManager = inAppPurchasesPlanManager
        userIsAdministrator = ServiceLocator.stores.sessionManager.defaultRoles.contains(.administrator)
        wpcomPlans = []
        entitledWpcomPlanIDs = []
    }

    /// Retrieves all In-App Purchases WPCom plans
    ///
    @MainActor
    func fetchPlans() async {
        if let plan {
            DDLogInfo("Default plan details loaded: \(plan.name)")
        }
        do {
            guard await inAppPurchasesPlanManager.inAppPurchasesAreSupported() else {
                DDLogError("IAP not supported")
                return
            }

            self.wpcomPlans = try await inAppPurchasesPlanManager.fetchPlans()
            await loadUserEntitlements()
        } catch {
            // TODO: Handle errors
            // https://github.com/woocommerce/woocommerce-ios/issues/9886
            DDLogError("fetchPlans \(error)")
        }
    }

    /// Triggers the purchase of the specified In-App Purchases WPCom plans by the passed plan ID
    /// linked to the current site ID
    ///
    @MainActor
    func purchasePlan(with planID: String) async {
        do {
            // TODO: Deal with purchase result
            // https://github.com/woocommerce/woocommerce-ios/issues/9886
            let _ = try await inAppPurchasesPlanManager.purchasePlan(with: planID, for: self.siteID)
        } catch {
            // TODO: Handle errors
            DDLogError("purchasePlan \(error)")
        }
    }

    /// Retrieves a specific In-App Purchase WPCom plan from the available products
    ///
    func retrievePlanDetailsIfAvailable(_ type: AvailableInAppPurchasesWPComPlans) -> WPComPlanProduct? {
        let match = type.rawValue
        guard let wpcomPlanProduct = wpcomPlans.first(where: { $0.id == match }) else {
            return nil
        }
        return wpcomPlanProduct
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
            // TODO: Handle errors
            // https://github.com/woocommerce/woocommerce-ios/issues/9886
            DDLogError("loadEntitlements \(error)")
        }
    }
}

extension UpgradesViewModel {
    enum AvailableInAppPurchasesWPComPlans: String {
        case essentialMonthly = "debug.woocommerce.express.essential.monthly"
    }
}
