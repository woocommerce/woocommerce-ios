import Foundation
import Storage
import StoreKit
import Networking

public class InAppPurchaseStore: Store {
    // ISO 3166-1 Alpha-3 country code representation.
    private let supportedCountriesCodes = ["USA"]
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
        case .purchaseProduct(let siteID, let productID, let completion):
            purchaseProduct(siteID: siteID, productID: productID, completion: completion)
        case .retryWPComSyncForPurchasedProduct(let productID, let completion):
            Task {
                do {
                    completion(.success(try await retryWPComSyncForPurchasedProduct(with: productID)))
                } catch {
                    completion(.failure(error))
                }
            }
        case .inAppPurchasesAreSupported(completion: let completion):
            Task {
                completion(await inAppPurchasesAreSupported())
            }
        case .userIsEntitledToProduct(productID: let productID, completion: let completion):
            Task {
                do {
                    completion(.success(try await userIsEntitledToProduct(with: productID)))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}

private extension InAppPurchaseStore {
    func loadProducts(completion: @escaping (Result<[StoreKit.Product], Error>) -> Void) {
        Task {
            do {
                try await assertInAppPurchasesAreSupported()
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

    func purchaseProduct(siteID: Int64, productID: String, completion: @escaping (Result<StoreKit.Product.PurchaseResult, Error>) -> Void) {
        Task {
            do {
                try await assertInAppPurchasesAreSupported()

                guard let product = try await StoreKit.Product.products(for: [productID]).first else {
                    return completion(.failure(Errors.transactionProductUnknown))
                }

                logInfo("Purchasing product \(product.id) for site \(siteID)")
                var purchaseOptions: Set<StoreKit.Product.PurchaseOption> = []
                if let appAccountToken = AppAccountToken.tokenWithSiteId(siteID) {
                    logInfo("Generated appAccountToken \(appAccountToken) for site \(siteID)")
                    purchaseOptions.insert(.appAccountToken(appAccountToken))
                }


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
                logError("Error purchasing product \(productID) for site \(siteID): \(error)")
                completion(.failure(error))
            }
        }
    }

    func handleCompletedTransaction(_ result: VerificationResult<StoreKit.Transaction>) async throws {
        guard case .verified(let transaction) = result else {
            // Ignore unverified transactions.
            // TODO: handle errors
            logError("Transaction unverified")
            return
        }

        if let revocationDate = transaction.revocationDate {
            // Refunds are handled in the backend
            logInfo("Ignoring update about revoked (\(revocationDate)) transaction \(transaction.id)")
        } else if let expirationDate = transaction.expirationDate,
            expirationDate < Date() {
            // Do nothing, this subscription is expired.
            logInfo("Ignoring update about expired (\(expirationDate)) transaction \(transaction.id)")
        } else if transaction.isUpgraded {
            // Do nothing, there is an active transaction
            // for a higher level of service.
            logInfo("Ignoring update about upgraded transaction \(transaction.id)")
        } else {
            // Provide access to the product
            logInfo("Verified transaction \(transaction.id) (Original ID: \(transaction.originalID)) for product \(transaction.productID)")
            try await submitTransaction(transaction)
        }
        logInfo("Marking transaction \(transaction.id) as finished")
        await transaction.finish()
    }

    func retryWPComSyncForPurchasedProduct(with id: String) async throws {
        try await assertInAppPurchasesAreSupported()

        guard let verificationResult = await Transaction.currentEntitlement(for: id) else {
            // The user doesn't have a valid entitlement for this product
            throw Errors.transactionProductUnknown
        }

        guard await Transaction.unfinished.contains(verificationResult) else {
            // The transaction is finished. Return successfully
            return
        }

        try await handleCompletedTransaction(verificationResult)
    }

    func assertInAppPurchasesAreSupported() async throws {
        guard await inAppPurchasesAreSupported() else {
            throw Errors.inAppPurchasesNotSupported
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

        let receiptData = try await getAppReceipt()

        logInfo("Sending transaction to API for site \(siteID)")
        let orderID = try await remote.createOrder(
            for: siteID,
            price: priceInCents,
            productIdentifier: product.id,
            appStoreCountryCode: countryCode,
            receiptData: receiptData
        )
        logInfo("Successfully registered purchase with Order ID \(orderID)")

    }

    func userIsEntitledToProduct(with id: String) async throws -> Bool {
        guard let verificationResult = await Transaction.currentEntitlement(for: id) else {
            // The user hasn't purchased this product.
            return false
        }

        switch verificationResult {
        case .verified(_):
            return true
        case .unverified(_, let verificationError):
            throw verificationError
        }
    }

    func getAppReceipt(refreshIfMissing: Bool = true) async throws -> Data {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped) else {
            if refreshIfMissing {
                logInfo("No app receipt found, refreshing")
                try await InAppPurchaseReceiptRefreshRequest.request()
                return try await getAppReceipt(refreshIfMissing: false)
            }
            throw Errors.missingAppReceipt
        }
        return receiptData
    }

    func getProductIdentifiers() async throws -> [String] {
        guard useBackend else {
            logInfo("Using hardcoded identifiers")
            return Constants.identifiers
        }
        return try await remote.loadProducts()
    }

    func inAppPurchasesAreSupported() async -> Bool {
        guard let countryCode = await Storefront.current?.countryCode else {
            return false
        }

        return supportedCountriesCodes.contains(countryCode)
    }

    func listenForTransactions() {
        assert(listenTask == nil, "InAppPurchaseStore.listenForTransactions() called while already listening for transactions")

        listenTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    try await self?.handleCompletedTransaction(result)
                } catch {
                    self?.logError("Error handling transaction update: \(error)")
                }
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
        case inAppPurchasesNotSupported
    }

    enum Constants {
        static let identifiers = [
            "debug.woocommerce.ecommerce.monthly"
        ]
    }
}
