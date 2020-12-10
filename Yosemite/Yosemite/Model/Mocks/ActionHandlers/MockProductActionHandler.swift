import Foundation
import Storage

struct MockProductActionHandler: MockActionHandler {

    typealias ActionType = ProductAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .requestMissingProducts(let order, let onCompletion):
                requestMissingProducts(for: order, onCompletion: onCompletion)
            case .retrieveProducts(let siteID, let productIDs, _, _, let onCompletion):
                retrieveProducts(siteId: siteID, productIds: productIDs, onCompletion: onCompletion)
            case .synchronizeProducts(let siteID, _, _, _, _, _, _, let excludedProductIDs, _, let onCompletion):
                synchronizeProducts(siteID: siteID, excludedProductIDs: excludedProductIDs, onCompletion: onCompletion)
            default: unimplementedAction(action: action)
        }
    }

    func synchronizeProducts(siteID: Int64, excludedProductIDs: [Int64], onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        let products = objectGraph.products(forSiteId: siteID, without: excludedProductIDs)
        save(mocks: products, as: StorageProduct.self) { error in
            if let error = error {
                onCompletion(.failure(error))
                return
            }

            /// Indicate that no more products are coming
            onCompletion(.success(false))
        }
    }

    func retrieveProducts(
        siteId: Int64,
        productIds: [Int64],
        onCompletion: @escaping (Result<(products: [Product], hasNextPage: Bool), Error>) -> Void
    ) {
        let products = objectGraph.products(forSiteId: siteId, productIds: productIds)
        save(mocks: products, as: StorageProduct.self) { (error) in
            if let error = error {
                onCompletion(.failure(error))
                return
            }

            onCompletion(.success((products, false)))
        }
    }

    func requestMissingProducts(for order: Order, onCompletion: @escaping (Error?) -> Void) {
        let productIds = order.items.map { $0.productID }.uniqued()
        let products = objectGraph.products(forSiteId: order.siteID, productIds: productIds)
        save(mocks: products, as: StorageProduct.self, onCompletion: onCompletion)
    }
}
