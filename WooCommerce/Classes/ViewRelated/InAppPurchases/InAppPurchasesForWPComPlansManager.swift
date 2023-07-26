import Foundation
import StoreKit
import Yosemite

protocol WPComPlanProduct {
    // The localized product name, to be used as title in UI
    var displayName: String { get }
    // The localized product description
    var description: String { get }
    // The unique product identifier. To be used in further actions e.g purchasing a product
    var id: String { get }
    // The localized price, including currency
    var displayPrice: String { get }
}

extension StoreKit.Product: WPComPlanProduct {}

typealias InAppPurchaseResult = StoreKit.Product.PurchaseResult

protocol InAppPurchasesForWPComPlansProtocol {
    /// Retrieves asynchronously all WPCom plans In-App Purchases products.
    ///
    func fetchPlans() async throws -> [WPComPlanProduct]

    /// Returns whether the user is entitled the WPCom plan identified with the passed id.
    ///
    /// - Parameters:
    ///     - id: the id of the WPCom plan whose entitlement is to be verified
    ///
    func userIsEntitledToPlan(with id: String) async throws -> Bool

    /// Triggers the purchase of WPCom plan specified by the passed product id, linked to the passed site Id.
    ///
    /// - Parameters:
    ///     id: the id of the WPCom plan to be purchased
    ///     remoteSiteId: the id of the site linked to the purchasing plan
    ///
    func purchasePlan(with id: String, for remoteSiteId: Int64) async throws -> InAppPurchaseResult

    /// Retries forwarding the WPCom plan purchase to our backend, so the plan can be unlocked.
    /// This can happen when the purchase was previously successful but unlocking the WPCom plan request
    /// failed.
    ///
    /// - Parameters:
    ///     id: the id of the purchased WPCom plan whose unlock failed
    ///
    func retryWPComSyncForPurchasedPlan(with id: String) async throws

    /// Returns whether In-App Purchases are supported for the current user configuration
    ///
    func inAppPurchasesAreSupported() async -> Bool

    /// Returns whether the site has any current In-App Purchases product
    ///
    func siteHasCurrentInAppPurchases(siteID: Int64) async -> Bool
}

final class InAppPurchasesForWPComPlansManager: InAppPurchasesForWPComPlansProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    @MainActor
    func fetchPlans() async throws -> [WPComPlanProduct] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.loadProducts(completion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    @MainActor
    func userIsEntitledToPlan(with id: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.userIsEntitledToProduct(productID: id, completion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    @MainActor
    func purchasePlan(with id: String, for remoteSiteId: Int64) async throws -> InAppPurchaseResult {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.purchaseProduct(siteID: remoteSiteId, productID: id, completion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    @MainActor
    func retryWPComSyncForPurchasedPlan(with id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.retryWPComSyncForPurchasedProduct(productID: id, completion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    @MainActor
    func inAppPurchasesAreSupported() async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.inAppPurchasesAreSupported(completion: { result in
                continuation.resume(returning: result)
            }))
        }
    }

    @MainActor
    func siteHasCurrentInAppPurchases(siteID: Int64) async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.siteHasCurrentInAppPurchases(siteID: siteID) { result in
                continuation.resume(returning: result)
            })
        }
    }
}
