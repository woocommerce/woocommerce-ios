import Foundation
import StoreKit
import Yosemite

protocol WPComPlanProduct {
    var displayName: String { get }
    var description: String { get }
    var id: String { get }
    var displayPrice: String { get }
}

enum InAppPurchasesForWPComPlansError: Error {
    case productNotFound
}

extension StoreKit.Product: WPComPlanProduct {}

enum WPComPlanProductTransactionStatus {
    case notStarted // Neither purchased through Apple nor the WPCom plan was unlocked
    case pending // In-App purchase was successful but the WPCom plan unlock request is pending
    case finished // In-App purchase and WPCom plan unlock succesful
}

protocol InAppPurchasesForWPComPlansProtocol {
    func fetchProducts() async throws -> [WPComPlanProduct]
    func transactionStatusForProduct(with id: String) async -> WPComPlanProductTransactionStatus
    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws
    func inAppPurchasesAreSupported() async -> Bool
}

final class InAppPurchasesForWPComPlansManager: InAppPurchasesForWPComPlansProtocol {
    private let stores = ServiceLocator.stores
    // ISO 3166-1 Alpha-3 country code representation.
    private let supportedCountriesCodes = ["USA"]

    func fetchProducts() async throws -> [WPComPlanProduct] {
        try await fetchStoreKitProducts()
    }

    func transactionStatusForProduct(with id: String) async -> WPComPlanProductTransactionStatus {
        guard let result = await Transaction.latest(for: id) else {
            return .notStarted
        }

        return await Transaction.unfinished.contains(result) ? .pending : .finished
    }

    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws {
        guard let storeKitProduct = try await fetchStoreKitProducts().first(where: { $0.id == id }) else {
            throw InAppPurchasesForWPComPlansError.productNotFound
        }

        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.purchaseProduct(siteID: remoteSiteId, product: storeKitProduct, completion: { result in
                switch result {
                case .success(_):
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func inAppPurchasesAreSupported() async -> Bool {
        guard let countryCode = await Storefront.current?.countryCode else {
            return false
        }

        return supportedCountriesCodes.contains(countryCode)
    }

    private func fetchStoreKitProducts() async throws -> [StoreKit.Product] {
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
}
