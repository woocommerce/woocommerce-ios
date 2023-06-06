import Foundation
import SwiftUI

///
///
///
@MainActor
final class UpgradesViewModel: ObservableObject {

    private let inAppPurchasesForWPComPlansManager: InAppPurchasesForWPComPlansManager
    @Published var products: [WPComPlanProduct]
    @Published var entitledProductIDs: Set<String>

    init() {
        inAppPurchasesForWPComPlansManager = InAppPurchasesForWPComPlansManager()
        products = []
        entitledProductIDs = []
    }

    ///
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
            DDLogError("loadEntitlements \(error)")
        }
    }

    ///
    ///
    func loadProducts() async {
        do {
            self.products = try await inAppPurchasesForWPComPlansManager.fetchProducts()
            await loadUserEntitlements()
        } catch {
            DDLogError("loadProducts \(error)")
        }
    }
}
