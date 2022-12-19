import Foundation
import StoreKit

#if DEBUG

/// Only used during store creation development before IAP server side is ready.
struct MockInAppPurchases {
    struct Plan: WPComPlanProduct {
        let displayName: String
        let description: String
        let id: String
        let displayPrice: String
    }

    private let fetchProductsDuration: UInt64
    private let products: [WPComPlanProduct]
    private let userIsEntitledToProduct: Bool
    private let isIAPSupported: Bool

    /// - Parameter fetchProductsDuration: How long to wait until the mock plan is returned, in nanoseconds.
    /// - Parameter products: WPCOM products to return for purchase.
    /// - Parameter userIsEntitledToProduct: Whether the user is entitled to the matched IAP product.
    init(fetchProductsDuration: UInt64 = 1_000_000_000,
         products: [WPComPlanProduct] = Defaults.products,
         userIsEntitledToProduct: Bool = false,
         isIAPSupported: Bool = true) {
        self.fetchProductsDuration = fetchProductsDuration
        self.products = products
        self.userIsEntitledToProduct = userIsEntitledToProduct
        self.isIAPSupported = isIAPSupported
    }
}

extension MockInAppPurchases: InAppPurchasesForWPComPlansProtocol {
    func fetchProducts() async throws -> [WPComPlanProduct] {
        try await Task.sleep(nanoseconds: fetchProductsDuration)
        return products
    }

    func userIsEntitledToProduct(with id: String) async throws -> Bool {
        userIsEntitledToProduct
    }

    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws -> InAppPurchaseResult {
        // Returns `.pending` in case of success because `StoreKit.Transaction` cannot be easily mocked.
        .pending
    }

    func retryWPComSyncForPurchasedProduct(with id: String) async throws {
        // no-op
    }

    func inAppPurchasesAreSupported() async -> Bool {
        isIAPSupported
    }
}

private extension MockInAppPurchases {
    enum Defaults {
        static let products: [WPComPlanProduct] = [
            Plan(displayName: "Debug Monthly",
                 description: "1 Month of Debug Woo",
                 id: "debug.woocommerce.ecommerce.monthly",
                 displayPrice: "$69.99")
        ]
    }
}

#endif
