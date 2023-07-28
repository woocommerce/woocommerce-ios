import Foundation
import StoreKit
@testable import WooCommerce

/// Only used during store creation development before IAP server side is ready.
struct MockInAppPurchasesForWPComPlansManager {
    struct Plan: WPComPlanProduct {
        let displayName: String
        let description: String
        let id: String
        let displayPrice: String
    }

    private let fetchPlansDelayInNanoseconds: UInt64
    private let plans: [WPComPlanProduct]
    private let userIsEntitledToPlan: Bool
    private let isIAPSupported: Bool

    /// - Parameter fetchPlansDelayInNanoseconds: How long to wait until the mock plan is returned, in nanoseconds.
    /// - Parameter plans: WPCom plans to return for purchase.
    /// - Parameter userIsEntitledToProduct: Whether the user is entitled to the matched IAP product.
    init(fetchPlansDelayInNanoseconds: UInt64 = 1_000_000_000,
         plans: [WPComPlanProduct] = Defaults.debugEcommercePlans,
         userIsEntitledToPlan: Bool = false,
         isIAPSupported: Bool = true) {
        self.fetchPlansDelayInNanoseconds = fetchPlansDelayInNanoseconds
        self.plans = plans
        self.userIsEntitledToPlan = userIsEntitledToPlan
        self.isIAPSupported = isIAPSupported
    }
}

extension MockInAppPurchasesForWPComPlansManager: InAppPurchasesForWPComPlansProtocol {
    func fetchPlans() async throws -> [WPComPlanProduct] {
        try await Task.sleep(nanoseconds: fetchPlansDelayInNanoseconds)
        return plans
    }

    func userIsEntitledToPlan(with id: String) async throws -> Bool {
        userIsEntitledToPlan
    }

    func purchasePlan(with id: String, for remoteSiteId: Int64) async throws -> InAppPurchaseResult {
        // Returns `.pending` in case of success because `StoreKit.Transaction` cannot be easily mocked.
        .pending
    }

    func retryWPComSyncForPurchasedPlan(with id: String) async throws {
        // no-op
    }

    func inAppPurchasesAreSupported() async -> Bool {
        isIAPSupported
    }

    func siteHasCurrentInAppPurchases(siteID: Int64) async -> Bool {
        userIsEntitledToPlan
    }
}

extension MockInAppPurchasesForWPComPlansManager {
    enum Defaults {
        static let debugEcommercePlans: [WPComPlanProduct] = [
            Plan(displayName: "Debug Monthly",
                 description: "1 Month of Debug Woo",
                 id: "debug.woocommerce.ecommerce.monthly",
                 displayPrice: "$69.99")
        ]
        static let essentialInAppPurchasesPlans: [WPComPlanProduct] = [
            Plan(displayName: "Essential Monthly",
                 description: "1 Month of Essential",
                 id: "woocommerce.express.essential.monthly",
                 displayPrice: "$99.99")
        ]
    }
}
