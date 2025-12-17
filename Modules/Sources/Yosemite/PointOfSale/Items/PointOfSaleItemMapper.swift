import Foundation
import class WooFoundation.CurrencySettings
import class WooFoundation.CurrencyFormatter
import NetworkingCore

public protocol PointOfSaleItemMapperProtocol {
    func mapProductsToPOSItems(products: [POSProduct]) -> [POSItem]
    func mapVariationsToPOSItems(variations: [POSProductVariation], parentProduct: POSVariableParentProduct) -> [POSItem]
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
            let isGiftCard = isGiftCardProduct(product.metaData)

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
                                                           stockStatusKey: product.stockStatusKey,
                                                           downloadable: product.downloadable,
                                                           isGiftCard: isGiftCard))
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
                                 parentProductName: parentProduct.name,
                                 downloadable: variation.downloadable))
        }
    }

    private func formatPrice(_ price: String) -> String {
        let zeroOrPlaceholder = currencyFormatter.formatAmount("0") ?? "-"
        return currencyFormatter.formatAmount(price) ?? zeroOrPlaceholder
    }

    /// Checks if a product is a gift card based on its meta_data.
    /// Gift cards have `_gift_card: "yes"` in their meta_data.
    private func isGiftCardProduct(_ metaData: [MetaData]) -> Bool {
        metaData.contains { $0.key == "_gift_card" && $0.value.stringValue == "yes" }
    }
}
