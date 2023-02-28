import Alamofire
import Foundation

/// In-app Purchases Endpoints
///
public class InAppPurchasesRemote: Remote {
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
        completion: @escaping (Swift.Result<Int, Error>) -> Void) {
            let parameters: [String: Any] = [
                Constants.siteIDKey: siteID,
                Constants.priceKey: price,
                Constants.productIDKey: productIdentifier,
                Constants.appStoreCountryCodeKey: appStoreCountryCode,
                Constants.originalTransactionId: originalTransactionId
            ]
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
        originalTransactionId: UInt64
    ) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            createOrder(
                for: siteID,
                price: price,
                productIdentifier: productIdentifier,
                appStoreCountryCode: appStoreCountryCode,
                originalTransactionId: originalTransactionId
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

        static let siteIDKey = "site_id"
        static let priceKey = "price"
        static let productIDKey = "product_id"
        static let appStoreCountryCodeKey = "appstore_country"
        static let originalTransactionId = "original_transaction_id"
    }
}
