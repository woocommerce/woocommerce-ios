import Foundation
import SwiftUI

/// ViewModel for the Upgrades View
/// Drives the site's available In-App Purchases plan upgrades
///
@MainActor
final class UpgradesViewModel: ObservableObject {

    private let inAppPurchasesPlanManager: InAppPurchasesForWPComPlansManager
    private let siteID: Int64

    @Published var wpcomPlanProducts: [WPComPlanProduct]
    @Published var entitledWpcomPlanProductIDs: Set<String>

    init(siteID: Int64) {
        self.siteID = siteID
        // TODO: Inject dependencies
        // https://github.com/woocommerce/woocommerce-ios/issues/9884
        inAppPurchasesPlanManager = InAppPurchasesForWPComPlansManager()
        wpcomPlanProducts = []
        entitledWpcomPlanProductIDs = []
    }

    /// Iterates through all available products (In-App Purchases WPCom plans) and checks whether the merchant is entitled
    ///
    func loadUserEntitlements() async {
        do {
            for wpcomPlan in self.wpcomPlanProducts {
                if try await inAppPurchasesPlanManager.userIsEntitledToProduct(with: wpcomPlan.id) {
                    self.entitledWpcomPlanProductIDs.insert(wpcomPlan.id)
                } else {
                    self.entitledWpcomPlanProductIDs.remove(wpcomPlan.id)
                }
            }
        } catch {
            // TODO: Handle errors
            // https://github.com/woocommerce/woocommerce-ios/issues/9886
            DDLogError("loadEntitlements \(error)")
        }
    }

    /// Retrieves all products (In-App Purchases WPCom plans)
    ///
    func loadProducts() async {
        do {
            guard await inAppPurchasesPlanManager.inAppPurchasesAreSupported() else {
                DDLogError("IAP not supported")
                return
            }

            self.wpcomPlanProducts = try await inAppPurchasesPlanManager.fetchProducts()
            await loadUserEntitlements()
        } catch {
            // TODO: Handle errors
            // https://github.com/woocommerce/woocommerce-ios/issues/9886
            DDLogError("loadProducts \(error)")
        }
    }

    /// Triggers the purchase of the specified In-App Purchases WPCom plans by the passed product ID
    /// linked to the current site ID
    ///
    func purchaseProduct(with productID: String) async {
        do {
            // TODO: Deal with purchase result
            // https://github.com/woocommerce/woocommerce-ios/issues/9886
            let _ = try await inAppPurchasesPlanManager.purchaseProduct(with: productID, for: self.siteID)
        } catch {
            // TODO: Handle errors
            DDLogError("purchaseProduct \(error)")
        }
    }

    /// Retrieves a specific In-App Purchase WPCOM plan from the available products
    ///
    func retrievePlanDetailsIfAvailable(_ type: AvailableInAppPurchasesWPComPlans ) -> WPComPlanProduct? {
        let match = type.rawValue
        guard let wpcomPlanProduct = wpcomPlanProducts.first(where: { $0.id == match }) else {
            return nil
        }
        return wpcomPlanProduct
    }
}

extension UpgradesViewModel {
    enum AvailableInAppPurchasesWPComPlans: String {
        case essentialMonthly = "debug.woocommerce.express.essential.monthly"
    }
}
