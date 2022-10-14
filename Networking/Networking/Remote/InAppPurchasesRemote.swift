import Alamofire
import Foundation

public class InAppPurchasesRemote: Remote {
    public func loadProducts(completion: @escaping (Swift.Result<[String], Error>) -> Void) {
        let dotComRequest = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: Constants.productsPath)
        let request = augmentedRequestWithAppId(dotComRequest)
        let mapper = InAppPurchasesProductMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    public func createOrder(
        for siteID: Int64,
        price: Int,
        productIdentifier: String,
        appStoreCountryCode: String,
        receiptData: Data,
        completion: @escaping (Swift.Result<Int, Error>) -> Void) {
            let dotComRequest = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: Constants.ordersPath)
            let request = augmentedRequestWithAppId(dotComRequest)
            let mapper = InAppPurchaseOrderResultMapper()
            enqueue(request, mapper: mapper, completion: completion)
        }
}

// MARK: - Async methods

public extension InAppPurchasesRemote {
    func loadProducts() async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            loadProducts { result in
                continuation.resume(with: result)
            }
        }
    }

    func createOrder(
        for siteID: Int64,
        price: Int,
        productIdentifier: String,
        appStoreCountryCode: String,
        receiptData: Data
    ) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            createOrder(
                for: siteID,
                price: price,
                productIdentifier: productIdentifier,
                appStoreCountryCode: appStoreCountryCode,
                receiptData: receiptData
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
}

private extension InAppPurchasesRemote {
    func augmentedRequestWithAppId(_ request: URLRequestConvertible) -> URLRequestConvertible {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              var augmented = try? request.asURLRequest() else {
            return request
        }

        augmented.setValue(bundleIdentifier, forHTTPHeaderField: "X-APP-ID")

        return augmented
    }
}

private extension InAppPurchasesRemote {
    enum Constants {
        static let productsPath = "iap/products"
        static let ordersPath = "iap/orders"
    }
}
