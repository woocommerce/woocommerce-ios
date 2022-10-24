import Foundation
import Storage
import StoreKit
import Networking

public class InAppPurchaseStore: Store {
    private var listenTask: Task<Void, Error>?
    private let remote: InAppPurchasesRemote
    private var useBackend = true

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        remote = InAppPurchasesRemote(network: network)
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
            _ = try? await getAppReceipt()

            do {
                logInfo("Loading products...")
                let identifiers = try await getProductIdentifiers()
                logInfo("Requesting StoreKit products: \(identifiers)")
                let products = try await StoreKit.Product.products(for: identifiers)
                logInfo("Obtained product list from StoreKit: \(products.map({ $0.id }))")
                completion(.success(products))
            } catch {
                logError("Failed obtaining product list from StoreKit: \(error)")
                completion(.failure(error))
            }
        }
    }

    func purchaseProduct(siteID: Int64, product: StoreKit.Product, completion: @escaping (Result<StoreKit.Product.PurchaseResult, Error>) -> Void) {
        Task {
            logInfo("Purchasing product \(product.id) for site \(siteID)")
            var purchaseOptions: Set<StoreKit.Product.PurchaseOption> = []
            if let appAccountToken = AppAccountToken.tokenWithSiteId(siteID) {
                logInfo("Generated appAccountToken \(appAccountToken) for site \(siteID)")
                purchaseOptions.insert(.appAccountToken(appAccountToken))
            }

            do {
                logInfo("Purchasing product \(product.id) for site \(siteID) with options \(purchaseOptions)")
                let purchaseResult = try await product.purchase(options: purchaseOptions)
                if case .success(let result) = purchaseResult {
                    logInfo("Purchased product \(product.id) for site \(siteID): \(result)")
                    try await handleCompletedTransaction(result)
                } else {
                    logError("Ignorning unsuccessful purchase: \(purchaseResult)")
                }
                completion(.success(purchaseResult))
            } catch {
                logError("Error purchasing product \(product.id) for site \(siteID): \(error)")
                completion(.failure(error))
            }
        }
    }

    func handleCompletedTransaction(_ result: VerificationResult<StoreKit.Transaction>) async throws {
        switch result {
        case .verified(let transaction):
            logInfo("Verified transaction \(transaction.id) (Original ID: \(transaction.originalID)) for product \(transaction.productID)")
            // FIXME: Don't finish the transaction until it's been handled. For testing only
            await transaction.finish()
            try await submitTransaction(transaction)
//            await transaction.finish()
        case .unverified:
            // TODO: handle errors
            logError("Transaction unverified")
        }
    }

    func submitTransaction(_ transaction: StoreKit.Transaction) async throws {
        guard useBackend else {
            return
        }
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

        logInfo("Transaction receipt: \(transaction.jsonRepresentation)")

//        await RefreshRequest.start()

        let receiptData = try await getAppReceipt()

        logInfo("Sending transaction to API for site \(siteID)")
        _ = try await remote.createOrder(
            for: siteID,
            price: priceInCents,
            productIdentifier: product.id,
            appStoreCountryCode: countryCode,
            receiptData: receiptData
        )
    }

    func getAppReceipt(refreshIfMissing: Bool = true) async throws -> Data {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped) else {
            logError("No app receipt")
            if refreshIfMissing {
                logInfo("Refreshing app receipt")
                try await InAppPurchaseReceiptRefreshRequest.request()
                return try await getAppReceipt(refreshIfMissing: false)
            }
            throw Errors.missingAppReceipt
        }
        logInfo("App receipt: \(receiptData)")

        for await result in Transaction.currentEntitlements {
            logInfo("Current entitlement: \(result)")
        }
        return receiptData
    }

    func getProductIdentifiers() async throws -> [String] {
        guard useBackend else {
            logInfo("Using hardcoded identifiers")
            return Constants.identifiers
        }
        logInfo("Requesting product identifiers from the API")
        return try await remote.loadProducts()
    }

    func listenForTransactions() {
        assert(listenTask == nil, "InAppPurchaseStore.listenForTransactions() called while already listening for transactions")

        listenTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                try? await self?.handleCompletedTransaction(result)
            }
        }
    }

    func logInfo(_ message: String,
                 file: StaticString = #file,
                 function: StaticString = #function,
                 line: UInt = #line) {
        DDLogInfo("[💰IAP Store] \(message)", file: file, function: function, line: line)
    }

    func logError(_ message: String,
                 file: StaticString = #file,
                 function: StaticString = #function,
                 line: UInt = #line) {
        DDLogError("[💰IAP Store] \(message)", file: file, function: function, line: line)
    }
}

public extension InAppPurchaseStore {
    enum Errors: Error {
        case transactionMissingAppAccountToken
        case appAccountTokenMissingSiteIdentifier
        case transactionProductUnknown
        case storefrontUnknown
        case missingAppReceipt
    }

    enum Constants {
        static let identifiers = [
            "debug.woocommerce.ecommerce.monthly"
        ]
    }
}
