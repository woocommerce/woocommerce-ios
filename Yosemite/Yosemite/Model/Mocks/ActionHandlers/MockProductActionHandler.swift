import Foundation
import Storage
import Networking

struct MockProductActionHandler: MockActionHandler {

    typealias ActionType = ProductAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    private let productStore: ProductStore

    init(objectGraph: MockObjectGraph, storageManager: StorageManagerType) {
        self.objectGraph = objectGraph
        self.storageManager = storageManager

        productStore = ProductStore(dispatcher: Dispatcher(), storageManager: storageManager, network: NullNetwork())
    }

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
        upsert(products: products) {
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
        upsert(products: products) {
            onCompletion(.success((products, false)))
        }
    }

    func requestMissingProducts(for order: Order, onCompletion: @escaping (Error?) -> Void) {
        let productIds = order.items.map { $0.productID }.uniqued()
        let products = objectGraph.products(forSiteId: order.siteID, productIds: productIds)

        upsert(products: products) {
            onCompletion(nil)
        }
    }

    func upsert(products: [Product], onCompletion: @escaping () -> ()) {
        let storage = storageManager.writerDerivedStorage

        storage.perform {
            productStore.upsertStoredProducts(readOnlyProducts: products, in: storage)
        }

        storageManager.saveDerivedType(derivedStorage: storage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}
