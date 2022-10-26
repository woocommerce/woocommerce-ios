import Foundation
import StoreKit
import Yosemite

protocol WPComPlanProduct {
    var displayName: String { get }
    var description: String { get }
    var id: String { get }
    var displayPrice: String { get }
}

extension StoreKit.Product: WPComPlanProduct {}

enum WPComPlanProductTransactionStatus {
    case notStarted // Neither purchased through Apple nor the WPCom plan was unlocked
    case pending // In-App purchase was successful but the WPCom plan unlock request is pending
    case finished // In-App purchase and WPCom plan unlock succesful
}

protocol InAppPurchasesForWPComPlansProtocol {
    func fetchProducts() async throws -> [WPComPlanProduct]
    func purchase(product: WPComPlanProduct, for remoteSiteId: Int64) async throws
    func inAppPurchasesAreSupported() async -> Bool
}

final class InAppPurchasesForWPComPlansManager: InAppPurchasesForWPComPlansProtocol {
    private let stores = ServiceLocator.stores
    // ISO 3166-1 Alpha-3 country code representation.
    private let supportedCountriesCodes = ["USA"]

    func fetchProducts() async throws -> [WPComPlanProduct] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.loadProducts(completion: { result in
                switch result {
                case .success(let products):
                    continuation.resume(returning: products)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func transactionStatus(for product: WPComPlanProduct) async -> WPComPlanProductTransactionStatus {
        guard let result = await Transaction.latest(for: product.id) else {
            return .notStarted
        }

        return await Transaction.unfinished.contains(result) ? .pending : .finished
    }

    func purchase(product: WPComPlanProduct, for remoteSiteId: Int64) async throws {
        guard let storeKitProduct = product as? StoreKit.Product else {
            return
        }

        stores.dispatch(InAppPurchaseAction.purchaseProduct(siteID: remoteSiteId, product: storeKitProduct, completion: { _ in }))
    }

    func inAppPurchasesAreSupported() async -> Bool {
        guard let countryCode = await Storefront.current?.countryCode else {
            return false
        }

        return supportedCountriesCodes.contains(countryCode)
    }
}
