import Alamofire
import Foundation

/// In-app Purchases Endpoints
///
public class InAppPurchasesRemote: Remote {
    public typealias InAppPurchasesTransactionResult = Swift.Result<InAppPurchasesTransactionResponse, Error>
    /// Retrieves a list of product identifiers available for purchase
    ///
    /// - Parameters:
    ///     - completion: Closure to be executed upon completion
    ///
    public func loadProducts(completion: @escaping (Swift.Result<[String], Error>) -> Void) {
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: Constants.productsPath, headers: headersWithAppId)
        let mapper = InAppPurchasesProductMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Checks the WPCOM billing system for whether or not an In-app Purchase transaction has been handled
    ///
    /// Handled transactions are those which can be found in the WPCOM billing system. Unhandled transactions are those which couldn't be found.
    /// We return the Site ID associated with the handled transaction as part of the InAppPurchasesTransactionResponse, or a "transaction not found"
    /// response if has not been handled yet.
    ///
    /// - Parameters:
    ///     - transactionID: The transactionID of the specific transaction (not originalTransactionID)
    ///     - completion: Closure to be executed upon completion.
    ///
    public func retrieveHandledTransactionResult(for transactionID: UInt64,
                                                 completion: @escaping (InAppPurchasesTransactionResult) -> Void ) {
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .get,
                                    path: Constants.transactionsPath + "/\(transactionID)",
                                    headers: headersWithAppId)
        let mapper = InAppPurchasesTransactionMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Creates a new order for a new In-app Purchase
    /// - Parameters:
    ///     - siteID: Site the purchase is for
    ///     - price: An integer representation of the price in cents (5.99 -> 599)
    ///     - productIdentifier: The IAP sku for the product
    ///     - appStoreCountryCode: The country of the user's App Store
    ///     - originalTransactionId: The original transaction id of the transaction
    ///     - completion: Closure to be executed upon completion
    ///
    public func createOrder(
        for siteID: Int64,
        price: Int,
        productIdentifier: String,
        appStoreCountryCode: String,
        originalTransactionId: UInt64,
        transactionId: UInt64,
        subscriptionGroupId: String?,
        completion: @escaping (Swift.Result<Int, Error>) -> Void) {
            var parameters: [String: Any] = [
                Constants.siteIDKey: siteID,
                Constants.priceKey: price,
                Constants.productIDKey: productIdentifier,
                Constants.appStoreCountryCodeKey: appStoreCountryCode,
                Constants.originalTransactionIdKey: originalTransactionId,
                Constants.transactionIdKey: transactionId
            ]
            if let subscriptionGroupId {
                parameters[Constants.subscriptionGroupIdKey] = subscriptionGroupId
            }
            let request = DotcomRequest(
                wordpressApiVersion: .wpcomMark2,
                method: .post,
                path: Constants.ordersPath,
                parameters: parameters,
                headers: headersWithAppId
            )
            let mapper = InAppPurchaseOrderResultMapper()
            enqueue(request, mapper: mapper, completion: completion)
        }
}

// MARK: - Async methods

public extension InAppPurchasesRemote {
    /// Retrieves a list of product identifiers available for purchase
    ///
    /// - Returns: a list of product identifiers.
    ///
    func loadProducts() async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            loadProducts { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Checks the WPCOM billing system for whether or not an In-app Purchase transaction has been handled
    ///
    ///- Returns: A InAppPurchasesTransactionResponse, which will contain the siteID the transactionID belongs to for handled transactions,
    /// or a "transaction not found" response for unhandled transactions
    ///
    func retrieveHandledTransactionResult(for transactionID: UInt64) async throws -> InAppPurchasesTransactionResponse {
        try await withCheckedThrowingContinuation { continuation in
            retrieveHandledTransactionResult(for: transactionID) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Creates a new order for a new In-app Purchase
    /// - Parameters:
    ///     - siteID: Site the purchase is for
    ///     - price: An integer representation of the price in cents (5.99 -> 599)
    ///     - productIdentifier: The IAP sku for the product
    ///     - appStoreCountryCode: The country of the user's App Store
    ///     - originalTransactionId: The original transaction id of the transaction
    ///
    /// - Returns: The ID of the created order.
    ///
    func createOrder(
        for siteID: Int64,
        price: Int,
        productIdentifier: String,
        appStoreCountryCode: String,
        originalTransactionId: UInt64,
        transactionId: UInt64,
        subscriptionGroupId: String?
    ) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            createOrder(
                for: siteID,
                price: price,
                productIdentifier: productIdentifier,
                appStoreCountryCode: appStoreCountryCode,
                originalTransactionId: originalTransactionId,
                transactionId: transactionId,
                subscriptionGroupId: subscriptionGroupId
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
}

private extension InAppPurchasesRemote {
    var headersWithAppId: [String: String]? {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return nil
        }

        return [
            "X-APP-ID": bundleIdentifier
        ]
    }
}

private extension InAppPurchasesRemote {
    enum Constants {
        static let productsPath = "iap/products"
        static let ordersPath = "iap/orders"
        static let transactionsPath = "iap/transactions"

        static let siteIDKey = "site_id"
        static let priceKey = "price"
        static let productIDKey = "product_id"
        static let appStoreCountryCodeKey = "appstore_country"
        static let originalTransactionIdKey = "original_transaction_id"
        static let transactionIdKey = "transaction_id"
        static let subscriptionGroupIdKey = "subscription_group_id"
    }
}
