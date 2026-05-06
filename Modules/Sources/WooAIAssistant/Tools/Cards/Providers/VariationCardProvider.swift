import CocoaLumberjackSwift
import Foundation
import Storage
import Yosemite

@MainActor
public final class VariationCardProvider: CardEntityProvider {

    private let siteID: Int64
    private let storageManager: StorageManagerType
    private let dispatchAction: @Sendable (Action) -> Void

    public init(siteID: Int64,
                storageManager: StorageManagerType,
                dispatchAction: @escaping @Sendable (Action) -> Void) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.dispatchAction = dispatchAction
    }

    public func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        guard refs.isEmpty == false else { return [:] }

        var outcomes: [CardRef: CardEntityOutcome] = [:]
        var misses: [CardRef] = []
        for ref in refs {
            if let variation = storageManager.viewStorage
                .loadProductVariation(siteID: siteID, productVariationID: ref.id)?.toReadOnly() {
                outcomes[ref] = outcome(for: variation, parentID: ref.parentID)
            } else {
                misses.append(ref)
            }
        }

        guard misses.isEmpty == false else { return outcomes }

        let fetchResults = await withTaskGroup(of: (CardRef, Result<Yosemite.ProductVariation, Error>).self) { group in
            for ref in misses {
                group.addTask { @MainActor [dispatchAction] in
                    let result = await withCheckedContinuation { (cont: CheckedContinuation<Result<Yosemite.ProductVariation, Error>, Never>) in
                        let action = ProductVariationAction.retrieveProductVariation(
                            siteID: self.siteID,
                            productID: ref.parentID,
                            variationID: ref.id
                        ) { result in
                            cont.resume(returning: result)
                        }
                        dispatchAction(action)
                    }
                    return (ref, result)
                }
            }
            var collected: [CardRef: Result<Yosemite.ProductVariation, Error>] = [:]
            for await pair in group {
                collected[pair.0] = pair.1
            }
            return collected
        }

        for ref in misses {
            switch fetchResults[ref] {
            case .success:
                if let variation = storageManager.viewStorage
                    .loadProductVariation(siteID: siteID, productVariationID: ref.id)?.toReadOnly() {
                    outcomes[ref] = outcome(for: variation, parentID: ref.parentID)
                } else {
                    outcomes[ref] = .rejected(.notFound)
                }
            case .failure(let error):
                DDLogError("VariationCardProvider remote fetch failed for \(ref.id): \(error)")
                outcomes[ref] = .rejected(.fetchFailed)
            case .none:
                outcomes[ref] = .rejected(.fetchFailed)
            }
        }
        return outcomes
    }

    private func outcome(for variation: Yosemite.ProductVariation, parentID: Int64) -> CardEntityOutcome {
        if variation.status.rawValue == "trash" {
            return .rejected(.staleReference)
        }
        let payload = ProductVariationCardPayload(
            id: variation.productVariationID,
            parentID: parentID,
            name: variationDisplayName(from: variation.attributes),
            sku: variation.sku,
            price: variation.price,
            regularPrice: variation.regularPrice,
            salePrice: variation.salePrice,
            stockStatus: variation.stockStatus.rawValue,
            stockQuantity: variation.stockQuantity.map { NSDecimalNumber(decimal: $0).doubleValue },
            images: variation.image.map { [ProductCardPayload.Image(src: $0.src)] }
        )
        return .found(.variation(payload))
    }
}

/// Match REST: WC returns `name` joined from attribute options ("Black, Large").
/// Storage entities don't carry a precomputed name, so synthesize it here to
/// keep cache hits and REST hits visually identical in the renderer.
func variationDisplayName(from attributes: [ProductVariationAttribute]) -> String? {
    let joined = attributes.map(\.option).filter { $0.isEmpty == false }.joined(separator: ", ")
    return joined.isEmpty ? nil : joined
}
