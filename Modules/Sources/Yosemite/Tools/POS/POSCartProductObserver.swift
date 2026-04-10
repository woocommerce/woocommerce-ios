import CocoaLumberjackSwift
import Foundation
import GRDB
import Combine
import Storage
import class WooFoundation.CurrencySettings

/// Observes GRDB product/variation rows for items currently in a POS cart.
/// When observed rows change (e.g. after an incremental catalog sync), publishes
/// updated `POSItem` values so the cart can reflect current prices.
///
/// Caches the observed IDs internally — calling `observe` with the same IDs is a no-op.
public protocol POSCartProductObserving {
    /// Starts observing the given product and variation IDs in GRDB.
    /// Publishes updated `POSItem` values through the `items` publisher whenever the underlying rows change.
    /// Skips rebuilding the observation if the IDs haven't changed since the last call.
    func observe(productIDs: Set<Int64>, variationIDs: Set<Int64>)

    /// Publisher that emits updated `POSItem` values when observed GRDB rows change.
    var items: AnyPublisher<[POSItem], Never> { get }
}

@MainActor
public final class POSCartProductObserver: POSCartProductObserving {
    private let siteID: Int64
    private let grdbManager: GRDBManagerProtocol
    private let itemMapper: PointOfSaleItemMapperProtocol

    private var currentProductIDs: Set<Int64> = []
    private var currentVariationIDs: Set<Int64> = []
    private var observationCancellable: AnyCancellable?
    private let itemsSubject = PassthroughSubject<[POSItem], Never>()

    public var items: AnyPublisher<[POSItem], Never> {
        itemsSubject.eraseToAnyPublisher()
    }

    public init(siteID: Int64,
                grdbManager: GRDBManagerProtocol,
                currencySettings: CurrencySettings,
                itemMapper: PointOfSaleItemMapperProtocol? = nil) {
        self.siteID = siteID
        self.grdbManager = grdbManager
        self.itemMapper = itemMapper ?? PointOfSaleItemMapper(currencySettings: currencySettings)
    }

    public func observe(productIDs: Set<Int64>, variationIDs: Set<Int64>) {
        guard productIDs != currentProductIDs || variationIDs != currentVariationIDs else { return }
        currentProductIDs = productIDs
        currentVariationIDs = variationIDs

        guard !productIDs.isEmpty || !variationIDs.isEmpty else {
            observationCancellable = nil
            return
        }

        let siteID = self.siteID
        let itemMapper = self.itemMapper

        let observation = ValueObservation
            .tracking { database -> ObservationResult in
                let products: [POSProduct] = try productIDs.isEmpty ? [] : {
                    struct ProductWithRelations: Decodable, FetchableRecord {
                        let product: PersistedProduct
                        let images: [PersistedImage]?
                        let attributes: [PersistedProductAttribute]?
                    }

                    let records = try PersistedProduct
                        .filter(PersistedProduct.Columns.siteID == siteID)
                        .filter(productIDs.contains(PersistedProduct.Columns.id))
                        .including(all: PersistedProduct.images)
                        .including(all: PersistedProduct.attributes)
                        .asRequest(of: ProductWithRelations.self)
                        .fetchAll(database)

                    return records.map { record in
                        record.product.toPOSProduct(
                            images: (record.images ?? []).map { $0.toProductImage() },
                            attributes: (record.attributes ?? []).map { $0.toProductAttribute(siteID: record.product.siteID) }
                        )
                    }
                }()

                let variationResults: [(POSProductVariation, POSProduct)] = try variationIDs.isEmpty ? [] : {
                    struct VariationWithRelations: Decodable, FetchableRecord {
                        let persistedProductVariation: PersistedProductVariation
                        let attributes: [PersistedProductVariationAttribute]?
                        let image: PersistedImage?
                    }

                    let records = try PersistedProductVariation
                        .filter(PersistedProductVariation.Columns.siteID == siteID)
                        .filter(variationIDs.contains(PersistedProductVariation.Columns.id))
                        .including(all: PersistedProductVariation.attributes)
                        .including(optional: PersistedProductVariation.image)
                        .asRequest(of: VariationWithRelations.self)
                        .fetchAll(database)

                    return try records.compactMap { record in
                        let parentProductID = record.persistedProductVariation.productID

                        struct ParentProductWithAttributes: Decodable, FetchableRecord {
                            let product: PersistedProduct
                            let attributes: [PersistedProductAttribute]?
                        }

                        guard let parent = try PersistedProduct
                            .filter(PersistedProduct.Columns.siteID == siteID)
                            .filter(PersistedProduct.Columns.id == parentProductID)
                            .including(all: PersistedProduct.attributes)
                            .asRequest(of: ParentProductWithAttributes.self)
                            .fetchOne(database) else {
                            return nil
                        }

                        let variation = record.persistedProductVariation.toPOSProductVariation(
                            attributes: (record.attributes ?? []).map { $0.toProductVariationAttribute() },
                            image: record.image?.toProductImage()
                        )

                        let parentProduct = parent.product.toPOSProduct(
                            attributes: (parent.attributes ?? []).map { $0.toProductAttribute(siteID: parent.product.siteID) }
                        )

                        return (variation, parentProduct)
                    }
                }()

                return ObservationResult(products: products, variationResults: variationResults)
            }

        observationCancellable = observation
            .publisher(in: grdbManager.databaseConnection)
            .map { result -> [POSItem] in
                var items: [POSItem] = []

                items.append(contentsOf: itemMapper.mapProductsToPOSItems(products: result.products))

                for (variation, parentProduct) in result.variationResults {
                    let parentPOSProduct = POSVariableParentProduct(
                        id: POSItemIdentifier(underlyingType: .product, itemID: parentProduct.productID),
                        name: parentProduct.name,
                        productImageSource: parentProduct.images.first?.src,
                        productID: parentProduct.productID,
                        allAttributes: parentProduct.attributes
                    )

                    let mapped = itemMapper.mapVariationsToPOSItems(
                        variations: [variation],
                        parentProduct: parentPOSProduct
                    )
                    items.append(contentsOf: mapped)
                }

                return items
            }
            .catch { error -> Just<[POSItem]> in
                DDLogError("⛔️ POSCartProductObserver: GRDB observation error: \(error)")
                return Just([])
            }
            .sink { [weak self] items in
                self?.itemsSubject.send(items)
            }
    }
}

private struct ObservationResult {
    let products: [POSProduct]
    let variationResults: [(POSProductVariation, POSProduct)]
}
