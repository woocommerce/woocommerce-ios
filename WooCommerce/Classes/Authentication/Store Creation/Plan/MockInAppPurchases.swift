import Foundation
import StoreKit

#if DEBUG

/// Only used during store creation development before IAP server side is ready.
struct MockInAppPurchases: InAppPurchasesForWPComPlansProtocol {
    struct Plan: WPComPlanProduct {
        let displayName: String
        let description: String
        let id: String
        let displayPrice: String
    }

    func fetchProducts() async throws -> [WPComPlanProduct] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return [Plan(displayName: "Debug Monthly",
                     description: "1 Month of Debug Woo",
                     id: "debug.woocommerce.ecommerce.monthly",
                     displayPrice: "$69.99")]
    }

    func userIsEntitledToProduct(with id: String) async throws -> Bool {
        false
    }

    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws -> InAppPurchaseResult {
        // Return .pending in case of success because `StoreKit.Transaction` cannot be mocked for a success result.
        .pending
    }

    func retryWPComSyncForPurchasedProduct(with id: String) async throws {

    }

    func inAppPurchasesAreSupported() async -> Bool {
        true
    }
}

#endif
