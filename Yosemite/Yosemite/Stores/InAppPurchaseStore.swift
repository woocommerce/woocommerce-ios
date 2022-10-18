import Foundation
import Storage
import StoreKit
import Networking

public class InAppPurchaseStore: Store {
    private var listenTask: Task<Void, Error>?
//    private let remote: InAppPurchasesRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
//        self.remote = InAppPurchasesRemote(network: network)
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
                    try await handleCompletedTransaction(result)
                }
                completion(.success(purchaseResult))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func handleCompletedTransaction(_ result: VerificationResult<StoreKit.Transaction>) async throws {
        switch result {
        case .verified(let transaction):
            try await submitTransaction(transaction)
            await transaction.finish()
        case .unverified:
            // TODO: handle errors
            print("Transaction unverified")
        }
    }

    func submitTransaction(_ transaction: StoreKit.Transaction) async throws {
        // TODO: actually send this to the backend
        /*
        guard let appAccountToken = transaction.appAccountToken else {
            throw Errors.transactionMissingAppAccountToken
        }
        guard let siteID = AppAccountToken.siteIDFromToken(appAccountToken) else {
            throw Errors.appAccountTokenMissingSiteIdentifier
        }

        let products = try await StoreKit.Product.products(for: [transaction.productID])
        guard let product = products.first else {
            throw Errors.transactionProductUnknown
        }
        let priceInCents = Int(truncating: NSDecimalNumber(decimal: product.price * 100))
        guard let countryCode = await Storefront.current?.countryCode else {
            throw Errors.storefrontUnknown
        }
         _ = try await remote.createOrder(
            for: siteID,
            price: priceInCents,
            productIdentifier: product.id,
            appStoreCountryCode: countryCode,
            receiptData: transaction.jsonRepresentation
        )
        */
    }

    func listenForTransactions() {
        assert(listenTask == nil, "InAppPurchaseStore.listenForTransactions() called while already listening for transactions")

        listenTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                try? await self?.handleCompletedTransaction(result)
            }
        }
    }
}

public extension InAppPurchaseStore {
    enum Errors: Error {
        case transactionMissingAppAccountToken
        case appAccountTokenMissingSiteIdentifier
        case transactionProductUnknown
        case storefrontUnknown
    }
}
