import Foundation
import class WooFoundation.CurrencySettings
import class WooFoundation.CurrencyFormatter

public protocol PointOfSaleItemMapperProtocol {
    func mapProductsToPOSItems(products: [POSProduct]) -> [POSItem]
    func mapVariationsToPOSItems(variations: [POSProductVariation], parentProduct: POSVariableParentProduct) -> [POSItem]

    /// Maps a single product to a POSItem (for search results)
    func mapProductToPOSItem(product: POSProduct) -> POSItem?

    /// Maps a variation to a searchResultVariation POSItem (for FTS search results showing variations with parent context)
    func mapVariationToSearchResultPOSItem(variation: POSProductVariation, parentProduct: POSProduct) -> POSItem?
}

/// Maps products and variations to POSItems, and populates the output with:
/// - Formatted price based on store's currency settings.
/// - Product thumbnail, if any.
final class PointOfSaleItemMapper: PointOfSaleItemMapperProtocol {
    private let currencyFormatter: CurrencyFormatter

    init(currencySettings: CurrencySettings) {
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    func mapProductsToPOSItems(products: [POSProduct]) -> [POSItem] {
        return products.compactMap { product in
            let thumbnailSource = product.images.first?.src
            let id = POSItemIdentifier(underlyingType: .product, itemID: product.productID)

            switch product.productType {
                case .simple:
                return .simpleProduct(POSSimpleProduct(id: id,
                                                           name: product.name,
                                                           formattedPrice: formatPrice(product.price),
                                                           productImageSource: thumbnailSource,
                                                           productID: product.productID,
                                                           price: product.price,
                                                           manageStock: product.manageStock,
                                                           stockQuantity: product.stockQuantity,
                                                           stockStatusKey: product.stockStatusKey))
                case .variable:
                    return .variableParentProduct(POSVariableParentProduct(
                        id: id,
                        name: product.name,
                        productImageSource: thumbnailSource,
                        productID: product.productID,
                        allAttributes: product.attributesForVariations
                    ))
                default:
                    return nil
            }
        }
    }

    func mapVariationsToPOSItems(variations: [POSProductVariation], parentProduct: POSVariableParentProduct) -> [POSItem] {
        return variations.compactMap { variation in
            let id = POSItemIdentifier(underlyingType: .variation, itemID: variation.productVariationID)
            let variationName = ProductVariationFormatter().generateNameWithAttributeNames(
                for: variation,
                from: parentProduct.allAttributes,
                separator: ", "
            )
            return POSItem
                .variation(.init(id: id,
                                 name: variationName,
                                 formattedPrice: formatPrice(variation.price),
                                 price: variation.price,
                                 productImageSource: variation.image?.src,
                                 productID: variation.productID,
                                 variationID: variation.productVariationID,
                                 parentProductName: parentProduct.name))
        }
    }

    func mapProductToPOSItem(product: POSProduct) -> POSItem? {
        let thumbnailSource = product.images.first?.src
        let id = POSItemIdentifier(underlyingType: .product, itemID: product.productID)

        switch product.productType {
        case .simple:
            return .simpleProduct(POSSimpleProduct(id: id,
                                                   name: product.name,
                                                   formattedPrice: formatPrice(product.price),
                                                   productImageSource: thumbnailSource,
                                                   productID: product.productID,
                                                   price: product.price,
                                                   manageStock: product.manageStock,
                                                   stockQuantity: product.stockQuantity,
                                                   stockStatusKey: product.stockStatusKey))
        case .variable:
            return .variableParentProduct(POSVariableParentProduct(
                id: id,
                name: product.name,
                productImageSource: thumbnailSource,
                productID: product.productID,
                allAttributes: product.attributesForVariations
            ))
        default:
            return nil
        }
    }

    func mapVariationToSearchResultPOSItem(variation: POSProductVariation, parentProduct: POSProduct) -> POSItem? {
        let id = POSItemIdentifier(underlyingType: .variation, itemID: variation.productVariationID)
        let variationName = ProductVariationFormatter().generateNameWithAttributeNames(
            for: variation,
            from: parentProduct.attributesForVariations,
            separator: ", "
        )

        let posVariation = POSVariation(
            id: id,
            name: variationName,
            formattedPrice: formatPrice(variation.price),
            price: variation.price,
            productImageSource: variation.image?.src,
            productID: variation.productID,
            variationID: variation.productVariationID,
            parentProductName: parentProduct.name
        )

        let parentId = POSItemIdentifier(underlyingType: .product, itemID: parentProduct.productID)
        let thumbnailSource = parentProduct.images.first?.src
        let posParentProduct = POSVariableParentProduct(
            id: parentId,
            name: parentProduct.name,
            productImageSource: thumbnailSource,
            productID: parentProduct.productID,
            allAttributes: parentProduct.attributesForVariations
        )

        return .searchResultVariation(posVariation, parentProduct: posParentProduct)
    }

    private func formatPrice(_ price: String) -> String {
        let zeroOrPlaceholder = currencyFormatter.formatAmount("0") ?? "-"
        return currencyFormatter.formatAmount(price) ?? zeroOrPlaceholder
    }
}
