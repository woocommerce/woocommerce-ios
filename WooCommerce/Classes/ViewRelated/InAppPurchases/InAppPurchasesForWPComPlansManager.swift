import Foundation
import StoreKit
import Yosemite

//typealias InAppPurchaseResult = StoreKit.Product.PurchaseResult

protocol InAppPurchasesForWPComPlansProtocol {
    /// Retrieves asynchronously all WPCom plans In-App Purchases products.
    ///
    func fetchProducts() async throws -> [WPComPlanProduct]

    /// Returns whether the user is entitled the product identified with the passed id.
    ///
    /// - Parameters:
    ///     - id: the id of the product whose entitlement is to be verified
    ///
    func userIsEntitledToProduct(with id: String) async throws -> Bool

    /// Triggers the purchase of WPCom plan specified by the passed product id, linked to the passed site Id.
    ///
    /// - Parameters:
    ///     id: the id of the product to be purchased
    ///     remoteSiteId: the id of the site linked to the purchasing plan
    ///
    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws -> InAppPurchaseResult

    /// Retries forwarding the product purchase to our backend, so the plan can be unlocked.
    /// This can happen when the purchase was previously successful but unlocking the WPCom plan request
    /// failed.
    ///
    /// - Parameters:
    ///     id: the id of the purchased product whose WPCom plan unlock failed
    ///
    func retryWPComSyncForPurchasedProduct(with id: String) async throws

    /// Returns whether In-App Purchases are supported for the current user configuration
    ///
    func inAppPurchasesAreSupported() async -> Bool
}

@MainActor
final class InAppPurchasesForWPComPlansManager: InAppPurchasesForWPComPlansProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func fetchProducts() async throws -> [WPComPlanProduct] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.loadProducts(completion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    func userIsEntitledToProduct(with id: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.userIsEntitledToProduct(productID: id, completion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws -> InAppPurchaseResult {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.purchaseProduct(siteID: remoteSiteId, productID: id, completion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    func retryWPComSyncForPurchasedProduct(with id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.retryWPComSyncForPurchasedProduct(productID: id, completion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    func inAppPurchasesAreSupported() async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.inAppPurchasesAreSupported(completion: { result in
                continuation.resume(returning: result)
            }))
        }
    }
}
