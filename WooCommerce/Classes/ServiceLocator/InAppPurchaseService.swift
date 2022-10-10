import Foundation
import StoreKit

final class InAppPurchaseService {
    private var listenTask: Task<Void, Error>?

    private let identifiers = [
        "woocommerce_entry_monthly"
    ]

    deinit {
        listenTask?.cancel()
    }

    func fetchWordPressPlanProducts() async throws -> [StoreKit.Product] {
        // TODO: get identifiers from backend
        return try await StoreKit.Product.products(for: identifiers)
    }

    func purchaseWordPressPlan(for remoteSiteId: Int64, product: StoreKit.Product) async -> Bool {
        // TODO: Create order from siteID and get UUID
        let orderUUID = UUID()
        let purchaseResult = try? await product.purchase(options: [.appAccountToken(orderUUID)])
        switch purchaseResult {
        case .success(let result):
            await handleCompletedTransaction(result)
            return true
        default:
            // TODO: handle errors
            return false
        }
    }

    private func handleCompletedTransaction(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let transaction):
            // TODO: notify the backend about purchase
            await transaction.finish()
        case .unverified:
            // TODO: handle errors
            print("Transaction unverified")
        }
    }

    func listenForTransactions() {
        assert(listenTask == nil, "InAppPurchaseService.listenForTransactions() called while already listening for transactions")

        listenTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleCompletedTransaction(result)
            }
        }
    }
}
