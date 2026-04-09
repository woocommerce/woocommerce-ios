import Foundation
import GRDB
import Combine
import Storage
import class WooFoundation.CurrencySettings

/// Observes GRDB product/variation rows for items currently in a POS cart.
/// When observed rows change (e.g. after an incremental catalog sync), publishes
/// updated `POSItem` values so the cart can reflect current prices.
public protocol POSCartProductObserving {
    /// Starts observing the given product and variation IDs in GRDB.
    /// Publishes an array of updated `POSItem` values whenever the underlying rows change.
    /// Each call replaces the previous observation.
    func observe(productIDs: Set<Int64>, variationIDs: Set<Int64>) -> AnyPublisher<[POSItem], Never>
}

public final class POSCartProductObserver: POSCartProductObserving {
    private let siteID: Int64
    private let grdbManager: GRDBManagerProtocol
    private let itemMapper: PointOfSaleItemMapperProtocol

    public init(siteID: Int64,
                grdbManager: GRDBManagerProtocol,
                currencySettings: CurrencySettings,
                itemMapper: PointOfSaleItemMapperProtocol? = nil) {
        self.siteID = siteID
        self.grdbManager = grdbManager
        self.itemMapper = itemMapper ?? PointOfSaleItemMapper(currencySettings: currencySettings)
    }

    public func observe(productIDs: Set<Int64>, variationIDs: Set<Int64>) -> AnyPublisher<[POSItem], Never> {
        guard !productIDs.isEmpty || !variationIDs.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        let siteID = self.siteID
        let itemMapper = self.itemMapper

        let observation = ValueObservation
            .tracking { database -> ObservationResult in
                // Fetch products by ID
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

                // Fetch variations by ID, with their parent products for name generation
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

        return observation
            .publisher(in: grdbManager.databaseConnection)
            .map { result -> [POSItem] in
                var items: [POSItem] = []

                // Map simple products
                items.append(contentsOf: itemMapper.mapProductsToPOSItems(products: result.products))

                // Map variations with their parent products
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
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
    }
}

private struct ObservationResult {
    let products: [POSProduct]
    let variationResults: [(POSProductVariation, POSProduct)]
}
