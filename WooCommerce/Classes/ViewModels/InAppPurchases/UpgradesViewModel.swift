import Foundation
import SwiftUI

///
///
///
@MainActor
final class UpgradesViewModel: ObservableObject {

    private let inAppPurchasesForWPComPlansManager: InAppPurchasesForWPComPlansManager
    var siteID: Int64 {
        ServiceLocator.stores.sessionManager.defaultStoreID ?? 0
    }

    @Published var products: [WPComPlanProduct]
    @Published var entitledProductIDs: Set<String>

    init() {
        // TODO: Inject dependencies
        inAppPurchasesForWPComPlansManager = InAppPurchasesForWPComPlansManager()
        products = []
        entitledProductIDs = []
    }

    /// Iterates through all available products (In-App Purchases WPCom plans) and checks whether the merchant is entitled
    ///
    func loadUserEntitlements() async {
        do {
            for product in self.products {
                if try await inAppPurchasesForWPComPlansManager.userIsEntitledToProduct(with: product.id) {
                    self.entitledProductIDs.insert(product.id)
                } else {
                    self.entitledProductIDs.remove(product.id)
                }
            }
        } catch {
            // TODO: Handle errors
            DDLogError("loadEntitlements \(error)")
        }
    }

    /// Retrieves all products (In-App Purchases WPCom plans)
    ///
    func loadProducts() async {
        do {
            self.products = try await inAppPurchasesForWPComPlansManager.fetchProducts()
            await loadUserEntitlements()
        } catch {
            // TODO: Handle errors
            DDLogError("loadProducts \(error)")
        }
    }

    /// Triggers the purchase of the specified In-App Purchases WPCom plans by the passed product ID
    /// linked to the current site ID
    ///
    func purchaseProduct(with productID: String) async {
        do {
            // TODO: Deal with purchase result
            let _ = try await inAppPurchasesForWPComPlansManager.purchaseProduct(with: productID, for: siteID)
        } catch {
            // TODO: Handle errors
            DDLogError("purchaseProduct \(error)")
        }
    }
}
