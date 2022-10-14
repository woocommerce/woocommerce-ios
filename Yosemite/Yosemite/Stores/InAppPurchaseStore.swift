import Foundation
import Storage
import StoreKit
import Networking

public class InAppPurchaseStore: Store {
    private var listenTask: Task<Void, Error>?
    private let remote: InAppPurchasesRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = InAppPurchasesRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
        listenForTransactions()
    }

    deinit {
        listenTask?.cancel()
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: InAppPurchaseAction.self)
    }

    public override func onAction(_ action: Action) {
        guard let action = action as? InAppPurchaseAction else {
            assertionFailure("InAppPurchaseStore received an unsupported action")
            return
        }
        switch action {
        case .loadProducts(let completion):
            loadProducts(completion: completion)
        case .purchaseProduct(let siteID, let product, let completion):
            purchaseProduct(siteID: siteID, product: product, completion: completion)
        }
    }
}

private extension InAppPurchaseStore {
    func loadProducts(completion: @escaping (Result<[StoreKit.Product], Error>) -> Void) {
        Task {
            do {
                // TODO: use identifiers from remote
                // let identifiers = try await remote.loadProducts()
                let identifiers = [
                    "woocommerce_entry_monthly"
                ]
                let products = try await StoreKit.Product.products(for: identifiers)
                completion(.success(products))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func purchaseProduct(siteID: Int64, product: StoreKit.Product, completion: @escaping (Result<StoreKit.Product.PurchaseResult, Error>) -> Void) {
        Task {
            var purchaseOptions: Set<StoreKit.Product.PurchaseOption> = []
            if let appAccountToken = AppAccountToken.tokenWithSiteId(siteID) {
                purchaseOptions.insert(.appAccountToken(appAccountToken))
            }

            do {
                let purchaseResult = try await product.purchase(options: purchaseOptions)
                if case .success(let result) = purchaseResult {
                    await handleCompletedTransaction(result)
                }
                completion(.success(purchaseResult))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func handleCompletedTransaction(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let transaction):
            // TODO: notify the backend about purchase
            print("💰 Transaction: \(transaction)")
            await transaction.finish()
        case .unverified:
            // TODO: handle errors
            print("Transaction unverified")
        }
    }

    func listenForTransactions() {
        assert(listenTask == nil, "InAppPurchaseStore.listenForTransactions() called while already listening for transactions")

        listenTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleCompletedTransaction(result)
            }
        }
    }
}
