import CocoaLumberjackSwift
import Foundation
import Storage
import Yosemite

struct ProductUpdatePatch: Sendable {
    let name: String?
    let regularPrice: String?
    let salePrice: String?
    let stockQuantity: Int?
    let status: String?

    var hasAnyField: Bool {
        name != nil || regularPrice != nil || salePrice != nil || stockQuantity != nil || status != nil
    }

    var updatesPrice: Bool {
        regularPrice != nil || salePrice != nil
    }
}

struct BulkWriteResult: Sendable {
    struct FailedItem: Sendable {
        let id: Int64
        let message: String
    }

    let updatedIDs: [Int64]
    let failedItems: [FailedItem]
}

@MainActor
protocol AssistantProductsDataSourceProtocol: Sendable {
    func updateProduct(id: Int64, patch: ProductUpdatePatch) async -> Result<Yosemite.Product, Error>
    func bulkUpdateProducts(ids: [Int64], patch: ProductUpdatePatch) async -> Result<BulkWriteResult, Error>
}

@MainActor
final class AssistantProductsDataSource: AssistantProductsDataSourceProtocol, CardEntityDataSource {
    private let siteID: Int64
    private let storageManager: StorageManagerType
    private let dispatcher: StoreActionDispatcher

    init(siteID: Int64,
         storageManager: StorageManagerType,
         dispatchAction: @escaping @MainActor @Sendable (Action) -> Void) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.dispatcher = StoreActionDispatcher(dispatchAction: dispatchAction)
    }

    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        let lookup = await products(ids: refs.map(\.id))
        var outcomes: [CardRef: CardEntityOutcome] = [:]
        let productsByID = lookup.items.reduce(into: [Int64: Yosemite.Product]()) { keyed, product in
            keyed[product.productID] = product
        }
        for ref in refs {
            if let product = productsByID[ref.id] {
                outcomes[ref] = outcome(for: product)
            } else {
                outcomes[ref] = .rejected(lookup.fetchFailed ? .fetchFailed : .notFound)
            }
        }
        return outcomes
    }

    func updateProduct(id: Int64, patch: ProductUpdatePatch) async -> Result<Yosemite.Product, Error> {
        if patch.updatesPrice {
            let existing = await freshProduct(id: id)
            guard case .success(let product) = existing else {
                if case .failure(let error) = existing {
                    return .failure(error)
                }
                return .failure(AssistantDataSourceError.notFound("Product #\(id) was not found"))
            }
            if product.productType == .variable {
                return .failure(AssistantDataSourceError.variableProductPrice(productID: id))
            }
        }

        return await dispatcher.dispatch { completion in
            ProductAction.updateProductFields(siteID: self.siteID,
                                              productID: id,
                                              fields: patch.fields,
                                              onCompletion: completion)
        }
    }

    func bulkUpdateProducts(ids: [Int64], patch: ProductUpdatePatch) async -> Result<BulkWriteResult, Error> {
        let result = await freshProducts(ids: ids)
        guard case .success(let fetched) = result else {
            if case .failure(let error) = result {
                return .failure(error)
            }
            return .failure(AssistantDataSourceError.notFound("Products could not be refreshed before update"))
        }

        let productsByID = fetched.reduce(into: [Int64: Yosemite.Product]()) { keyed, product in
            keyed[product.productID] = product
        }
        var updatedIDs: [Int64] = []
        var failedItems: [BulkWriteResult.FailedItem] = []
        for id in ids {
            guard let product = productsByID[id] else {
                failedItems.append(.init(id: id, message: "Product #\(id) was not found"))
                continue
            }
            if patch.updatesPrice, product.productType == .variable {
                failedItems.append(.init(id: id, message: AssistantDataSourceError.variableProductPrice(productID: id).localizedDescription))
                continue
            }
            let updateResult: Result<Yosemite.Product, Error> = await dispatcher.dispatch { completion in
                ProductAction.updateProductFields(siteID: self.siteID,
                                                  productID: id,
                                                  fields: patch.fields,
                                                  onCompletion: completion)
            }
            switch updateResult {
            case .success(let product):
                updatedIDs.append(product.productID)
            case .failure(let error):
                if WriteOutcomeClassifier.isOutcomeUnknown(error) {
                    return .failure(error)
                }
                failedItems.append(.init(id: id, message: error.localizedDescription))
            }
        }
        return .success(BulkWriteResult(updatedIDs: updatedIDs, failedItems: failedItems))
    }

    private func product(id: Int64) async -> Result<Yosemite.Product, Error> {
        if let stored = storageManager.viewStorage.loadProduct(siteID: siteID, productID: id)?.toReadOnly() {
            return .success(stored)
        }
        return await dispatcher.dispatch { completion in
            ProductAction.retrieveProduct(siteID: self.siteID, productID: id, onCompletion: completion)
        }
    }

    private func freshProduct(id: Int64) async -> Result<Yosemite.Product, Error> {
        await dispatcher.dispatch { completion in
            ProductAction.retrieveProduct(siteID: self.siteID, productID: id, onCompletion: completion)
        }
    }

    private func freshProducts(ids: [Int64]) async -> Result<[Yosemite.Product], Error> {
        typealias ProductFetchResult = Result<(products: [Yosemite.Product], hasNextPage: Bool), Error>
        let result: ProductFetchResult = await dispatcher.dispatch { completion in
            ProductAction.retrieveProducts(siteID: self.siteID,
                                           productIDs: ids,
                                           pageSize: max(ids.count, 1),
                                           onCompletion: completion)
        }
        return result.map { $0.products }
    }

    private func products(ids: [Int64]) async -> CachedEntityLookup<Yosemite.Product> {
        let ids = Array(Set(ids))
        guard ids.isEmpty == false else {
            return CachedEntityLookup(items: [])
        }

        var cached: [Yosemite.Product] = []
        var missingIDs: [Int64] = []
        for id in ids {
            if let product = storageManager.viewStorage.loadProduct(siteID: siteID, productID: id)?.toReadOnly() {
                cached.append(product)
            } else {
                missingIDs.append(id)
            }
        }
        guard missingIDs.isEmpty == false else {
            return CachedEntityLookup(items: cached)
        }

        typealias ProductFetchResult = Result<(products: [Yosemite.Product], hasNextPage: Bool), Error>
        let result: ProductFetchResult = await dispatcher.dispatch { completion in
            ProductAction.retrieveProducts(siteID: self.siteID, productIDs: missingIDs, onCompletion: completion)
        }
        switch result {
        case .success(let fetched):
            return CachedEntityLookup(items: cached + fetched.products)
        case .failure(let error):
            DDLogError("AssistantProductsDataSource remote fetch failed: \(error)")
            return CachedEntityLookup(items: cached, fetchError: error)
        }
    }

    private func outcome(for product: Yosemite.Product) -> CardEntityOutcome {
        if product.statusKey == "trash" {
            return .rejected(.staleReference)
        }
        return .found(.product(CardEntityPayloadFactory.payload(from: product)))
    }
}

private extension ProductUpdatePatch {
    var fields: ProductUpdateFields {
        ProductUpdateFields(name: name,
                            regularPrice: regularPrice,
                            salePrice: salePrice,
                            stockQuantity: stockQuantity,
                            status: status)
    }
}

struct CachedEntityLookup<Entity: Sendable>: Sendable {
    let items: [Entity]
    let fetchError: Error?

    init(items: [Entity], fetchError: Error? = nil) {
        self.items = items
        self.fetchError = fetchError
    }

    var fetchFailed: Bool {
        fetchError != nil
    }
}

extension [BulkWriteResult.FailedItem] {
    func contains(id: Int64) -> Bool {
        contains { $0.id == id }
    }
}
