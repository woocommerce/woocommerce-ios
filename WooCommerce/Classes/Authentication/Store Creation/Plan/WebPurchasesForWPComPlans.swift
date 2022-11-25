import Foundation
import protocol Yosemite.StoresManager
import enum Yosemite.PaymentAction
import struct Yosemite.WPComPlan

/// An `InAppPurchasesForWPComPlansProtocol` implementation for purchasing a WPCOM plan in a webview.
struct WebPurchasesForWPComPlans {
    struct Plan: WPComPlanProduct, Equatable {
        let displayName: String
        let description: String
        let id: String
        let displayPrice: String
    }

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }
}

extension WebPurchasesForWPComPlans: InAppPurchasesForWPComPlansProtocol {
    func fetchProducts() async throws -> [WPComPlanProduct] {
        let result = await loadPlan(thatMatchesID: Constants.eCommerceMonthlyPlanProductID)
        switch result {
        case .success(let plan):
            return [plan].map { Plan(displayName: $0.name, description: "", id: "\($0.productID)", displayPrice: $0.formattedPrice) }
        case .failure(let error):
            throw error
        }
    }

    func userIsEntitledToProduct(with id: String) async throws -> Bool {
        // A newly created site does not have any WPCOM plans. In web, the user can purchase a WPCOM plan for every site.
        false
    }

    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws -> InAppPurchaseResult {
        let createCartResult = await createCart(productID: id, for: remoteSiteId)
        switch createCartResult {
        case .success:
            // `StoreCreationCoordinator` will then launch the checkout webview after a cart is created.
            return .pending
        case .failure(let error):
            throw error
        }
    }

    func retryWPComSyncForPurchasedProduct(with id: String) async throws {
        // no-op
    }

    func inAppPurchasesAreSupported() async -> Bool {
        // Web purchases are available for everyone and every site.
        true
    }
}

private extension WebPurchasesForWPComPlans {
    @MainActor
    func loadPlan(thatMatchesID productID: Int64) async -> Result<WPComPlan, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(PaymentAction.loadPlan(productID: productID) { result in
                continuation.resume(returning: result)
            })
        }
    }

    @MainActor
    func createCart(productID: String, for siteID: Int64) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(PaymentAction.createCart(productID: productID, siteID: siteID) { result in
                continuation.resume(returning: result)
            })
        }
    }
}

private extension WebPurchasesForWPComPlans {
    enum Constants {
        static let eCommerceMonthlyPlanProductID: Int64 = 1021
    }
}
