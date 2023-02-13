import Combine
import Foundation
import Storage
import StoreKit
import Networking

public protocol WPComPlanProduct {
    // The localized product name, to be used as title in UI
    var displayName: String { get }
    // The localized product description
    var description: String { get }
    // The unique product identifier. To be used in further actions e.g purchasing a product
    var id: String { get }
    // The localized price, including currency
    var displayPrice: String { get }
}

public enum InAppPurchaseResult {
    case success
    case userCancelled
    case pending
}

extension StoreKit.Product: WPComPlanProduct {}

extension SKProduct: WPComPlanProduct {
    public var displayName: String {
        localizedTitle
    }

    public var id: String {
        productIdentifier
    }

    public override var description: String {
        localizedDescription
    }

    public var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)!
    }
}

public class NewInAppPurchaseStore: Store {
    // ISO 3166-1 Alpha-3 country code representation.
    private let supportedCountriesCodes = ["USA"]
    private var listenTask: Task<Void, Error>?
    private let remote: InAppPurchasesRemote
    private var useBackend = true
    private var pauseTransactionListener = CurrentValueSubject<Bool, Never>(false)
    private let originalStoreKitFacade = InAppPurchasesProductsProvider()
    private var purchaseProductCompletion: ((Result<InAppPurchaseResult, Error>) -> Void)?

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        remote = InAppPurchasesRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
        SKPaymentQueue.default().add(self)
    }

    deinit {
        listenTask?.cancel()
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: InAppPurchaseAction.self)
    }

    public override func onAction(_ action: Action) {
        guard let action = action as? InAppPurchaseAction else {
            assertionFailure("NewInAppPurchaseStore received an unsupported action")
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

private extension NewInAppPurchaseStore {
    func loadProducts(completion: @escaping (Result<[WPComPlanProduct], Error>) -> Void) {
        Task {
            do {
                try await assertInAppPurchasesAreSupported()
                let identifiers = try await getProductIdentifiers()
                logInfo("Requesting StoreKit products: \(identifiers)")
                let products = try await originalStoreKitFacade.requestProducts(with: identifiers)
                logInfo("Obtained product list from StoreKit: \(products.map({ $0.id }))")
                completion(.success(products))
            } catch {
                logError("Failed obtaining product list from StoreKit: \(error)")
                completion(.failure(error))
            }
        }
    }

    func purchaseProduct(siteID: Int64, productID: String, completion: @escaping (Result<InAppPurchaseResult, Error>) -> Void) {
        Task {
            do {
                try await assertInAppPurchasesAreSupported()
                purchaseProductCompletion = completion
                let payment = SKMutablePayment()
                payment.applicationUsername = AppAccountToken.tokenWithSiteId(siteID)?.uuidString
                payment.productIdentifier = productID
                SKPaymentQueue.default().add(payment)
            } catch WordPressApiError.productPurchased {
                // Ignore errors for existing purchase
                logInfo("Existing order found for transaction on site \(siteID), ignoring")
            } catch {
                logError("Error purchasing product \(productID) for site \(siteID): \(error)")
                completion(.failure(error))
            }
        }
    }

    func submitTransaction(_ transaction: SKPaymentTransaction) async throws {
        let productID = transaction.payment.productIdentifier
        debugPrint("applicationUsername \(transaction.payment.productIdentifier)")

        guard let applicationUsername = transaction.payment.applicationUsername,
              let uuid = UUID(uuidString: applicationUsername),
              let siteID = AppAccountToken.siteIDFromToken(uuid) else {
           throw Errors.appAccountTokenMissingSiteIdentifier
        }

        do {
            let receiptData = try await getAppReceipt()
            debugPrint("receipt data \(receiptData.base64EncodedString())")


            let products = try await originalStoreKitFacade.requestProducts(with: [productID])

            guard let product = products.first else {
                throw Errors.transactionProductUnknown
            }
            let priceInCents = product.price.intValue * 100
            guard let countryCode = await Storefront.current?.countryCode else {
                throw Errors.storefrontUnknown
            }

            logInfo("Sending transaction to API for site \(siteID)")

            let orderID = try await remote.createOrder(
                for: siteID,
                price: priceInCents,
                productIdentifier: productID,
                appStoreCountryCode: countryCode,
                receiptData: receiptData
            )

            transaction.finish()

            logInfo("Successfully registered purchase with Order ID \(orderID)")
        } catch WordPressApiError.productPurchased {
            // Ignore errors for existing purchase
            logInfo("Existing order found for transaction on site, ignoring")
        } catch {
            logError("Error purchasing product \(productID) for site \(siteID): \(error)")
            purchaseProductCompletion?(.failure(error))
        }
    }

    func handleCompletedTransaction(_ transaction: SKPaymentTransaction) {
        Task {
            do {
                try await submitTransaction(transaction)
                transaction.finish()
                purchaseProductCompletion?(.success(.success))
            } catch {
                logError("Error when handling a complete transaction \(error)")
                purchaseProductCompletion?(.failure(error))
            }
        }
    }

    func retryWPComSyncForPurchasedProduct(with id: String) async throws {
        try await assertInAppPurchasesAreSupported()

//        guard let verificationResult = await Transaction.currentEntitlement(for: id) else {
//            // The user doesn't have a valid entitlement for this product
//            throw Errors.transactionProductUnknown
//        }
//
//        guard await Transaction.unfinished.contains(verificationResult) else {
//            // The transaction is finished. Return successfully
//            return
//        }
//
//        try await handleCompletedTransaction(verificationResult)
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
        do {
            let orderID = try await remote.createOrder(
                for: siteID,
                price: priceInCents,
                productIdentifier: product.id,
                appStoreCountryCode: countryCode,
                receiptData: receiptData
            )
            logInfo("Successfully registered purchase with Order ID \(orderID)")
        } catch WordPressApiError.productPurchased {
            // Ignore errors for existing purchase
            logInfo("Existing order found for transaction \(transaction.id) on site \(siteID), ignoring")
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

extension NewInAppPurchaseStore: SKPaymentTransactionObserver {

  public func paymentQueue(_ queue: SKPaymentQueue,
                           updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
        debugPrint("transaction state \(transaction.transactionState)")
      switch transaction.transactionState {
      case .purchased:
          handleCompletedTransaction(transaction)
        break
      case .failed:
          if let error = transaction.error as? NSError {
              if error.domain == SKErrorDomain {
                  switch error.code {
                  case SKError.paymentCancelled.rawValue:
                      purchaseProductCompletion?(.success(.userCancelled))
                  default:
                      purchaseProductCompletion?(.failure(error))
                  }
              }
          }
        break
      case .restored:
        break
      case .deferred:
        break
      case .purchasing:
        break
      @unknown default:
          fatalError()
      }
    }
  }

  private func fail(transaction: SKPaymentTransaction) {
    print("fail...")
    if let transactionError = transaction.error as NSError?,
      let localizedDescription = transaction.error?.localizedDescription,
        transactionError.code != SKError.paymentCancelled.rawValue {
        print("Transaction Error: \(localizedDescription)")
      }

    SKPaymentQueue.default().finishTransaction(transaction)
  }
}

public extension NewInAppPurchaseStore {
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

        /// App receipt was missing, even after a refresh
        ///
        case missingAppReceipt

        /// In-app purchases are not supported for this user
        ///
        case inAppPurchasesNotSupported

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
                    "Couldn't determine App Stoure country",
                    comment: "Error message used when we can't determine the user's App Store country")
            case .missingAppReceipt:
                return NSLocalizedString(
                    "Couldn't retrieve app receipt",
                    comment: "Error message used when we can't read the app receipt")
            case .inAppPurchasesNotSupported:
                return NSLocalizedString(
                    "In-app purchases are not supported for this user yet",
                    comment: "Error message used when In-app purchases are not supported for this user/site")
            }
        }
    }

    enum Constants {
        static let identifiers = [
            "debug.woocommerce.ecommerce.monthly"
        ]
    }
}
