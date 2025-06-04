import Foundation
import class WooFoundation.CurrencyFormatter

/// Maps products and variations to POSItems, and populates the output with:
/// - Formatted price based on store's currency settings.
/// - Product thumbnail, if any.
final class PointOfSaleItemMapper {
    private let currencyFormatter: CurrencyFormatter

    init(currencyFormatter: CurrencyFormatter) {
        self.currencyFormatter = currencyFormatter
    }

    func mapProductsToPOSItems(products: [POSProduct]) -> [POSItem] {
        return products.compactMap { product in
            let thumbnailSource = product.images.first?.src

            switch product.productType {
                case .simple:
                    return .simpleProduct(POSSimpleProduct(id: UUID(),
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
                        id: UUID(),
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

    func mapVariationsToPOSItems(variations: [ProductVariation], parentProduct: POSVariableParentProduct) -> [POSItem] {
        return variations.compactMap { variation in
            let variationName = ProductVariationFormatter().generateNameWithAttributeNames(
                for: variation,
                from: parentProduct.allAttributes,
                separator: ", "
            )
            return POSItem
                .variation(.init(id: UUID(),
                                 name: variationName,
                                 formattedPrice: formatPrice(variation.price),
                                 price: variation.price,
                                 productImageSource: variation.image?.src,
                                 productID: variation.productID,
                                 variationID: variation.productVariationID,
                                 parentProductName: parentProduct.name))
        }
    }

    private func formatPrice(_ price: String) -> String {
        let zeroOrPlaceholder = currencyFormatter.formatAmount("0") ?? "-"
        return currencyFormatter.formatAmount(price) ?? zeroOrPlaceholder
    }
}