import Foundation
import enum Alamofire.AFError
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
    private let itemMapper: PointOfSaleItemMapperProtocol

    public init(currencySettings: CurrencySettings, itemMapper: PointOfSaleItemMapperProtocol? = nil) {
        self.itemMapper = itemMapper ?? PointOfSaleItemMapper(currencySettings: currencySettings)
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

            return .init(items: itemMapper.mapProductsToPOSItems(products: products),
                         hasMorePages: pagedProducts.hasMorePages,
                         totalItems: pagedProducts.totalItems)
        } catch AFError.explicitlyCancelled, is CancellationError {
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

            return .init(
                items: itemMapper.mapVariationsToPOSItems(variations: variations, parentProduct: parentProduct),
                hasMorePages: pagedVariations.hasMorePages,
                totalItems: pagedVariations.totalItems
            )
        } catch AFError.explicitlyCancelled, is CancellationError {
            throw PointOfSaleItemServiceError.requestCancelled
        }
    }
}
