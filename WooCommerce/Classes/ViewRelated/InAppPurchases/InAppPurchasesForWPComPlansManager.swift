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
    func userDidPurchaseProduct(with id: String) async throws -> Bool
    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws
    func retryWPComSyncForPurchasedProduct(with id: String) async throws
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
                switch result {
                case .success(let products):
                    continuation.resume(returning: products)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func userDidPurchaseProduct(with id: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.userDidPurchaseProduct(productID: id, completion: { result in
                switch result {
                case .success(let productIsPurchased):
                    continuation.resume(returning: productIsPurchased)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.purchaseProduct(siteID: remoteSiteId, productID: id, completion: { result in
                switch result {
                case .success(_):
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func retryWPComSyncForPurchasedProduct(with id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.retryWPComSyncForPurchasedProduct(productID: id, completion: { result in
                switch result {
                case .success(let products):
                    continuation.resume(returning: products)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
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
