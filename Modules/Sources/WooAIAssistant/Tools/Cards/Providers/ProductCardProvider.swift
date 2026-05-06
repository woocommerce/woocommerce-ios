import CocoaLumberjackSwift
import Foundation
import Storage
import Yosemite

@MainActor
final class ProductCardProvider: CardEntityProvider {

    private let siteID: Int64
    private let storageManager: StorageManagerType
    private let dispatchAction: @Sendable (Action) -> Void

    init(siteID: Int64,
         storageManager: StorageManagerType,
         dispatchAction: @escaping @Sendable (Action) -> Void) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.dispatchAction = dispatchAction
    }

    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        guard refs.isEmpty == false else { return [:] }

        var outcomes: [CardRef: CardEntityOutcome] = [:]
        var misses: [CardRef] = []
        for ref in refs {
            if let product = storageManager.viewStorage.loadProduct(siteID: siteID, productID: ref.id)?.toReadOnly() {
                outcomes[ref] = outcome(for: product)
            } else {
                misses.append(ref)
            }
        }

        guard misses.isEmpty == false else { return outcomes }

        typealias FetchResult = Result<(products: [Yosemite.Product], hasNextPage: Bool), Error>
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<FetchResult, Never>) in
            let action = ProductAction.retrieveProducts(siteID: siteID, productIDs: misses.map { $0.id }) { result in
                continuation.resume(returning: result)
            }
            dispatchAction(action)
        }

        switch result {
        case .success:
            for ref in misses {
                if let product = storageManager.viewStorage.loadProduct(siteID: siteID, productID: ref.id)?.toReadOnly() {
                    outcomes[ref] = outcome(for: product)
                } else {
                    outcomes[ref] = .rejected(.notFound)
                }
            }
        case .failure(let error):
            DDLogError("ProductCardProvider remote fetch failed: \(error)")
            for ref in misses {
                outcomes[ref] = .rejected(.fetchFailed)
            }
        }
        return outcomes
    }

    private func outcome(for product: Yosemite.Product) -> CardEntityOutcome {
        if product.statusKey == "trash" {
            return .rejected(.staleReference)
        }
        let payload = ProductCardPayload(
            id: product.productID,
            name: product.name,
            sku: product.sku,
            price: product.price,
            regularPrice: product.regularPrice,
            salePrice: product.salePrice,
            stockStatus: product.stockStatusKey,
            stockQuantity: product.stockQuantity.map { NSDecimalNumber(decimal: $0).doubleValue },
            type: product.productTypeKey,
            status: product.statusKey,
            images: product.images.map { ProductCardPayload.Image(src: $0.src) }
        )
        return .found(.product(payload))
    }
}
