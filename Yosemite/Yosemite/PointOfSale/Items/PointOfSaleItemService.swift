import Foundation
import enum Alamofire.AFError
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import struct Networking.PagedItems

public enum PointOfSaleItemServiceError: Error, Equatable {
    case requestFailed
    case requestCancelled
    case unknown
}

/// Product provider for the Point of Sale feature
///
public final class PointOfSaleItemService: PointOfSaleItemServiceProtocol {
    private let currencyFormatter: CurrencyFormatter

    public init(currencySettings: CurrencySettings) {
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    /// Provides a list of products for the Point of Sale, by fetching simple products using the fetch strategy, applying any eligibility criteria,
    /// and maps them to POSItem type.
    ///
    /// - pageNumber: Number of the page that should be retrieved. If none given, defaults to 1
    ///
    public func providePointOfSaleItems(pageNumber: Int = 1,
                                        fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        do {
            let pagedProducts = try await fetchStrategy.fetchProducts(pageNumber: pageNumber)
            let products = pagedProducts.items

            if pageNumber != 1 && products.count == 0 {
                return .init(items: [], hasMorePages: false, totalItems: 0)
            }

            return .init(items: mapProductsToPOSItems(products: products),
                         hasMorePages: pagedProducts.hasMorePages,
                         totalItems: pagedProducts.totalItems)
        } catch AFError.explicitlyCancelled {
            throw PointOfSaleItemServiceError.requestCancelled
        }
    }

    public func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct,
                                                 pageNumber: Int,
                                                 fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        do {
            let pagedVariations = try await fetchStrategy.fetchVariations(parentProductID: parentProduct.productID,
                                                                          pageNumber: pageNumber)
            let variations = pagedVariations.items
            // Remove this when WC version 9.7 has significant adoption in POS stores.
                .filter { !$0.downloadable }
            return .init(
                items: variations.compactMap({ variation in
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
                }),
                hasMorePages: pagedVariations.hasMorePages,
                totalItems: pagedVariations.totalItems
            )
        } catch AFError.explicitlyCancelled {
            throw PointOfSaleItemServiceError.requestCancelled
        }
    }

    // Maps result to POSItem, and populate the output with:
    // - Formatted price based on store's currency settings.
    // - Product thumbnail, if any.
    private func mapProductsToPOSItems(products: [POSProduct]) -> [POSItem] {
        return products.compactMap { product in
            let thumbnailSource = product.images.first?.src

            switch product.productType {
                case .simple:
                    return .simpleProduct(POSSimpleProduct(id: UUID(),
                                                           name: product.name,
                                                           formattedPrice: formatPrice(product.price),
                                                           productImageSource: thumbnailSource,
                                                           productID: product.productID,
                                                           price: product.price))
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

    private func formatPrice(_ price: String) -> String {
        let zeroOrPlaceholder = currencyFormatter.formatAmount("0") ?? "-"
        return currencyFormatter.formatAmount(price) ?? zeroOrPlaceholder
    }
}
