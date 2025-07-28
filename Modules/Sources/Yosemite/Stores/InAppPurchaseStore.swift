import Combine
import Foundation
import Storage
import StoreKit
import Networking

public class InAppPurchaseStore: Store {
    public typealias PurchaseCompletionHandler = (Result<StoreKit.Product.PurchaseResult, Error>) -> Void
    // ISO 3166-1 Alpha-3 country code representation.
    private let supportedCountriesCodes = ["USA"]
    private var listenTask: Task<Void, Error>?
    private let remote: InAppPurchasesRemote
    private var useBackend = true
    private var pauseTransactionListener = CurrentValueSubject<Bool, Never>(false)

    /// When an IAP transaction requires further action, e.g. Strong Customer Auth in a banking app
    /// or parental approval, it will be returned as a `.pending` transaction.
    /// In those cases, we handle the transaction when it comes up in the `.updates` stream of
    /// Transactions, which we listen to for handling unfinished transactions on app strat.
    /// `pendingTransactionCompletionHandler`, holds the completion handler so that we
    /// can update the original purchase flow, if it's still on screen.
    /// N.B. Apple do not notify us about declined pending transactions, so we cannot handle them –
    /// the user must dismiss the waiting screen and try again.
    /// https://developer.apple.com/forums/thread/685183?answerId=682554022#682554022
    private var pendingTransactionCompletionHandler: PurchaseCompletionHandler? = nil

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
        case .siteHasCurrentInAppPurchases(siteID: let siteID, completion: let completion):
            Task {
                completion(await siteHasCurrentInAppPurchases(siteID: siteID))
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

    func purchaseProduct(siteID: Int64, productID: String, completion: @escaping PurchaseCompletionHandler) {
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
                logInfo("Pausing transaction listener")
                pauseTransactionListener.send(true)
                defer {
                    logInfo("Resuming transaction listener")
                    pauseTransactionListener.send(false)
                }
                let purchaseResult = try await product.purchase(options: purchaseOptions)
                switch purchaseResult {
                case .success(let result):
                    guard case .verified(let transaction) = result else {
                        // Ignore unverified transactions.
                        logError("Transaction unverified: \(result)")
                        throw Errors.unverifiedTransaction
                    }
                    logInfo("Purchased product \(product.id) for site \(siteID): \(transaction)")

                    try await submitTransaction(transaction)
                    await transaction.finish()
                    completion(.success(purchaseResult))
                case .userCancelled:
                    logInfo("User cancelled the purchase flow")
                    completion(.success(purchaseResult))
                case .pending:
                    logInfo("Purchase returned in a pending state, it might succeed in the future")
                    pendingTransactionCompletionHandler = completion
                @unknown default:
                    logError("Unknown result for purchase: \(purchaseResult)")
                }
            } catch {
                logError("Error purchasing product \(productID) for site \(siteID): \(error)")
                if let purchaseError = error as? StoreKit.Product.PurchaseError {
                    completion(.failure(Errors.inAppPurchaseProductPurchaseFailed(purchaseError)))
                } else if let storeKitError = error as? StoreKitError {
                    completion(.failure(Errors.inAppPurchaseStoreKitFailed(storeKitError)))
                } else {
                    completion(.failure(error))
                }
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
        pendingTransactionCompletionHandler?(.success(.success(result)))
        pendingTransactionCompletionHandler = nil
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

        logInfo("Sending transaction to API for site \(siteID)")
        do {
            let orderID = try await remote.createOrder(
                for: siteID,
                price: priceInCents,
                productIdentifier: product.id,
                appStoreCountryCode: countryCode,
                originalTransactionId: transaction.originalID,
                transactionId: transaction.id,
                subscriptionGroupId: transaction.subscriptionGroupID
            )
            logInfo("Successfully registered purchase with Order ID \(orderID)")
        } catch WordPressApiError.productPurchased {
            throw Errors.transactionAlreadyAssociatedWithAnUpgrade
        } catch WordPressApiError.transactionReasonInvalid(let reasonMessage) {
            /// We ignore transactionReasonInvalid errors, usually these are renewals that
            /// MobilePay has already handled via Apple's server to server notifications
            /// [See #10075 for details](https://github.com/woocommerce/woocommerce-ios/issues/10075)
            logInfo("Unsupported transaction received: \(transaction.id) on site \(siteID), ignoring. \(reasonMessage)")
        } catch {
            // Rethrow any other error
            throw error
        }
    }

    func userIsEntitledToProduct(with id: String) async throws -> Bool {
        guard let verificationResult = await Transaction.currentEntitlement(for: id) else {
            // The user hasn't purchased this product.
            return false
        }

        switch verificationResult {
        case .verified:
            return true
        case .unverified(_, let verificationError):
            throw verificationError
        }
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

    /// Checks if the Site has current subscriptions via In-App Purchases
    ///
    func siteHasCurrentInAppPurchases(siteID: Int64) async -> Bool {
        for await transaction in Transaction.currentEntitlements {
            switch transaction {
            case .verified(let transaction):
                // If we have current entitlements, we check for its transaction token, and extract the associated siteID.
                // If this siteID matches the current siteID, then the site has current In-App Purchases.
                guard let token = transaction.appAccountToken,
                      let transactionSiteID = AppAccountToken.siteIDFromToken(token),
                      transactionSiteID == siteID else {
                    continue
                }
                return true
            default:
                break
            }
        }
        return false
    }

    /// For verified transactions, checks whether a transaction has been handled already on WPCOM end or not
    /// we'll mark handled transactions as `finish`. This indicates to the App Store that the app enabled the service to finish the transaction
    ///
    /// - Parameters:
    ///   - result: Represents the verification state of an In-App Purchase transaction
    ///   - transaction: A successful In-App purchase
    func handleVerifiedTransactionResult(_ result: VerificationResult<Transaction>, _ transaction: Transaction) async throws {
        Task { @MainActor in
            // This remote call needs to run in the main thread. Since the request is an AuthenticatedDotcomRequest it requires to instantiate a
            // WKWebView and inject a WPCOM token into it as part of the user agent in order to work, however, a WKWebView also requires to be
            // ran from the main thread only. This is not assured to happen unless we call the remote through the Action Dispatcher, and
            // could cause a runtime crash since there is no compiler-check to stop us from doing so.
            // https://github.com/woocommerce/woocommerce-ios/issues/10294
            let wpcomTransactionResponse = try await self.remote.retrieveHandledTransactionResult(for: transaction.id)
            if wpcomTransactionResponse.siteID != nil {
                await transaction.finish()
                self.logInfo("Marking transaction \(transaction.id) as finished")
            } else {
                try await self.handleCompletedTransaction(result)
                self.logInfo("Transaction \(transaction.id) not found in WPCOM")
            }
        }
    }

    func listenForTransactions() {
        assert(listenTask == nil, "InAppPurchaseStore.listenForTransactions() called while already listening for transactions")

        listenTask = Task.detached { [weak self] in
            guard let self else {
                return
            }
            for await result in Transaction.updates {
                switch result {
                case .unverified:
                    // Ignore unverified transactions.
                    self.logError("Transaction unverified")
                    break
                case .verified(let transaction):
                    do {
                        // Wait until the purchase finishes
                        _ = await self.pauseTransactionListener.values.contains(false)
                        try await self.handleVerifiedTransactionResult(result, transaction)
                    } catch {
                        self.logError("Error handling transaction \(transaction.id) update: \(error)")
                    }
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
    enum Errors: Error, LocalizedError {
        /// The purchase was successful but the transaction was unverified
        ///
        case unverifiedTransaction

        /// The purchase was successful but it's not associated to an account
        ///
        case transactionMissingAppAccountToken

        /// The transaction has an associated account but it can't be translated to a site
        ///
        case appAccountTokenMissingSiteIdentifier

        /// The transaction is associated with an unknown product
        ///
        case transactionProductUnknown

        /// The storefront for the user is unknown, and so we can't know their country code
        ///
        case storefrontUnknown

        /// In-app purchases are not supported for this user
        ///
        case inAppPurchasesNotSupported

        case inAppPurchaseProductPurchaseFailed(StoreKit.Product.PurchaseError)

        case inAppPurchaseStoreKitFailed(StoreKitError)

        case transactionAlreadyAssociatedWithAnUpgrade

        public var errorDescription: String? {
            switch self {
            case .unverifiedTransaction:
                return NSLocalizedString(
                    "The purchase transaction couldn't be verified",
                    comment: "Error message used when a purchase was successful but its transaction was unverified")
            case .transactionMissingAppAccountToken:
                return NSLocalizedString(
                    "Purchase transaction missing account information",
                    comment: "Error message used when the purchase transaction doesn't have the right metadata to associate to a specific site")
            case .appAccountTokenMissingSiteIdentifier:
                return NSLocalizedString(
                    "Purchase transaction can't be associated to a site",
                    comment: "Error message used when the purchase transaction doesn't have the right metadata to associate to a specific site")
            case .transactionProductUnknown:
                return NSLocalizedString(
                    "Purchase transaction received for an unknown product",
                    comment: "Error message used when we received a transaction for an unknown product")
            case .storefrontUnknown:
                return NSLocalizedString(
                    "Couldn't determine App Store country",
                    comment: "Error message used when we can't determine the user's App Store country")
            case .inAppPurchasesNotSupported:
                return NSLocalizedString(
                    "In-app purchases are not supported for this user yet",
                    comment: "Error message used when In-app purchases are not supported for this user/site")
            case .inAppPurchaseProductPurchaseFailed(let purchaseError):
                return NSLocalizedString(
                    "The In-App Purchase failed, with product purchase error: \(purchaseError)",
                    comment: "Error message used when a purchase failed")
            case .inAppPurchaseStoreKitFailed(let storeKitError):
                return NSLocalizedString(
                    "The In-App Purchase failed, with StoreKit error: \(storeKitError)",
                    comment: "Error message used when a purchase failed with a store kit error")
            case .transactionAlreadyAssociatedWithAnUpgrade:
                return NSLocalizedString(
                    "This In-App purchase was successful, but has already been used to upgrade a site. " +
                    "Please contact support for more help.",
                    comment: "Error message shown when the In-App Purchase transaction was already used " +
                    "for another upgrade – their money was taken, but this site is not upgraded.")
            }
        }

        public var errorCode: String {
            switch self {
            case .unverifiedTransaction:
                return "iap.T.100"
            case .inAppPurchasesNotSupported:
                return "iap.T.105"
            case .transactionProductUnknown:
                return "iap.T.110"
            case .inAppPurchaseProductPurchaseFailed(let purchaseError):
                switch purchaseError {
                case .invalidQuantity:
                    return "iap.T.115.1"
                case .productUnavailable:
                    return "iap.T.115.2"
                case .purchaseNotAllowed:
                    return "iap.T.115.3"
                case .ineligibleForOffer:
                    return "iap.T.115.4"
                case .invalidOfferIdentifier:
                    return "iap.T.115.5"
                case .invalidOfferPrice:
                    return "iap.T.115.6"
                case .invalidOfferSignature:
                    return "iap.T.115.7"
                case .missingOfferParameters:
                    return "iap.T.115.8"
                @unknown default:
                    return "iap.T.115.0"
                }
            case .inAppPurchaseStoreKitFailed(let storeKitError):
                switch storeKitError {
                case .unknown:
                    return "iap.T.120.1"
                case .userCancelled:
                    return "iap.T.120.2"
                case .networkError(let networkError):
                    return "iap.T.120.3.\(networkError.errorCode)"
                case .systemError:
                    return "iap.T.120.4"
                case .notAvailableInStorefront:
                    return "iap.T.120.5"
                case .notEntitled:
                    return "iap.T.120.6"
                @unknown default:
                    return "iap.T.120.0"
                }
            case .transactionMissingAppAccountToken:
                return "iap.A.100"
            case .appAccountTokenMissingSiteIdentifier:
                return "iap.A.105"
            case .storefrontUnknown:
                return "iap.A.110"
            case .transactionAlreadyAssociatedWithAnUpgrade:
                return "iap.A.115"
            }
        }
    }

    enum Constants {
        static let identifiers = [
            "debug.woocommerce.ecommerce.monthly"
        ]
    }
}
