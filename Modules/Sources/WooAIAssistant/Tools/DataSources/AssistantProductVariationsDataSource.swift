import CocoaLumberjackSwift
import Foundation
import Storage
import Yosemite

struct ProductVariationUpdatePatch: Sendable {
    let regularPrice: String?
    let salePrice: String?
    let stockQuantity: Int?
    let stockStatus: String?
    let sku: String?
    let status: String?

    var hasAnyField: Bool {
        regularPrice != nil || salePrice != nil || stockQuantity != nil || stockStatus != nil || sku != nil || status != nil
    }
}

struct ProductVariationBatchPatch: Sendable {
    let id: Int64
    let patch: ProductVariationUpdatePatch
}

@MainActor
protocol AssistantProductVariationsDataSourceProtocol: Sendable {
    func updateVariation(productID: Int64,
                         variationID: Int64,
                         patch: ProductVariationUpdatePatch) async -> Result<Yosemite.ProductVariation, Error>
    func bulkUpdateVariations(productID: Int64,
                              patches: [ProductVariationBatchPatch]) async -> Result<BulkWriteResult, Error>
}

@MainActor
final class AssistantProductVariationsDataSource: AssistantProductVariationsDataSourceProtocol, CardEntityDataSource {
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
        guard refs.isEmpty == false else { return [:] }

        return await withTaskGroup(of: (CardRef, CardEntityOutcome).self, returning: [CardRef: CardEntityOutcome].self) { group in
            for ref in refs {
                group.addTask {
                    let result = await self.variation(productID: ref.parentID, variationID: ref.id)
                    switch result {
                    case .success(let variation):
                        return (ref, await self.outcome(for: variation, parentID: ref.parentID))
                    case .failure(let error):
                        DDLogError("AssistantProductVariationsDataSource fetch failed for \(ref.id): \(error)")
                        return (ref, .rejected(.fetchFailed))
                    }
                }
            }
            var outcomes: [CardRef: CardEntityOutcome] = [:]
            for await (ref, outcome) in group {
                outcomes[ref] = outcome
            }
            return outcomes
        }
    }

    func updateVariation(productID: Int64,
                         variationID: Int64,
                         patch: ProductVariationUpdatePatch) async -> Result<Yosemite.ProductVariation, Error> {
        return await dispatcher.dispatch { completion in
            ProductVariationAction.updateProductVariationFields(siteID: self.siteID,
                                                                productID: productID,
                                                                variationID: variationID,
                                                                fields: patch.fields,
                                                                onCompletion: completion)
        }
    }

    func bulkUpdateVariations(productID: Int64,
                              patches: [ProductVariationBatchPatch]) async -> Result<BulkWriteResult, Error> {
        var updatedIDs: [Int64] = []
        var failedItems: [BulkWriteResult.FailedItem] = []
        for update in patches {
            let result: Result<Yosemite.ProductVariation, Error> = await dispatcher.dispatch { completion in
                ProductVariationAction.updateProductVariationFields(siteID: self.siteID,
                                                                    productID: productID,
                                                                    variationID: update.id,
                                                                    fields: update.patch.fields,
                                                                    onCompletion: completion)
            }
            switch result {
            case .success(let variation):
                updatedIDs.append(variation.productVariationID)
            case .failure(let error):
                if WriteOutcomeClassifier.isOutcomeUnknown(error) {
                    return .failure(error)
                }
                failedItems.append(.init(id: update.id, message: error.localizedDescription))
            }
        }
        return .success(BulkWriteResult(updatedIDs: updatedIDs, failedItems: failedItems))
    }

    private func variation(productID: Int64,
                           variationID: Int64) async -> Result<Yosemite.ProductVariation, Error> {
        if let stored = storageManager.viewStorage
            .loadProductVariation(siteID: siteID, productVariationID: variationID)?.toReadOnly() {
            guard stored.productID == productID else {
                return await freshVariation(productID: productID, variationID: variationID)
            }
            return .success(stored)
        }
        return await dispatcher.dispatch { completion in
            ProductVariationAction.retrieveProductVariation(siteID: self.siteID,
                                                            productID: productID,
                                                            variationID: variationID,
                                                            onCompletion: completion)
        }
    }

    private func freshVariation(productID: Int64,
                                variationID: Int64) async -> Result<Yosemite.ProductVariation, Error> {
        await dispatcher.dispatch { completion in
            ProductVariationAction.retrieveProductVariation(siteID: self.siteID,
                                                            productID: productID,
                                                            variationID: variationID,
                                                            onCompletion: completion)
        }
    }

    private func outcome(for variation: Yosemite.ProductVariation, parentID: Int64) -> CardEntityOutcome {
        if variation.status.rawValue == "trash" {
            return .rejected(.staleReference)
        }
        return .found(.variation(CardEntityPayloadFactory.payload(from: variation, parentID: parentID)))
    }
}

private extension ProductVariationUpdatePatch {
    var fields: ProductVariationUpdateFields {
        ProductVariationUpdateFields(regularPrice: regularPrice,
                                     salePrice: salePrice,
                                     stockQuantity: stockQuantity,
                                     stockStatus: stockStatus,
                                     sku: sku,
                                     status: status)
    }
}
