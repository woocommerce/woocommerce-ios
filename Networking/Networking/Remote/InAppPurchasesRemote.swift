import Foundation

public class InAppPurchasesRemote: Remote {
    public func loadProducts(for siteID: Int64, completion: @escaping (Result<[String], Error>) -> Void) {
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: Constants.productsPath)
        let mapper = InAppPurchasesProductMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    public func createOrder(
        for siteID: Int64,
        price: Int,
        productIdentifier: String,
        appStoreCountryCode: String,
        receiptData: Data,
        completion: @escaping (Result<Int, Error>) -> Void) {
            let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: Constants.ordersPath)
            let mapper = InAppPurchaseOrderResultMapper()
            enqueue(request, mapper: mapper, completion: completion)
        }
}

private extension InAppPurchasesRemote {
    enum Constants {
        static let productsPath = "iap/products"
        static let ordersPath = "iap/orders"
    }
}
