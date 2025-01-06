import Foundation
import protocol Networking.Network
import protocol Networking.ProductVariationsRemoteProtocol
import class Networking.ProductsRemote
import class Networking.ProductVariationsRemote
import class Networking.AlamofireNetwork
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

public enum PointOfSaleProductServiceError: Error {
    case requestFailed
    case unknown
}

/// Product provider for the Point of Sale feature
///
public final class PointOfSaleItemService: PointOfSaleItemServiceProtocol {
    private var siteID: Int64
    private let currencyFormatter: CurrencyFormatter
    private let productsRemote: ProductsRemote
    private let variationRemote: ProductVariationsRemoteProtocol
    private let isVariableProductsFeatureEnabled: Bool

    public init(siteID: Int64, currencySettings: CurrencySettings, network: Network, isVariableProductsFeatureEnabled: Bool) {
        self.siteID = siteID
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.productsRemote = ProductsRemote(network: network)
        self.variationRemote = ProductVariationsRemote(network: network)
        self.isVariableProductsFeatureEnabled = isVariableProductsFeatureEnabled
    }

    public convenience init(siteID: Int64,
                            currencySettings: CurrencySettings,
                            credentials: Credentials?,
                            isVariableProductsFeatureEnabled: Bool) {
        self.init(siteID: siteID,
                  currencySettings: currencySettings,
                  network: AlamofireNetwork(credentials: credentials),
                  isVariableProductsFeatureEnabled: isVariableProductsFeatureEnabled)
    }

    /// Provides a list of products for the Point of Sale, by fetching simple products from the remote, applying any eligibility criteria,
    /// and maps them to POSItem type.
    ///
    /// - pageNumber: Number of the page that should be retrieved. If none given, defaults to 1
    ///
    public func providePointOfSaleItems(pageNumber: Int = 1) async throws -> PagedItems<POSItem> {
        let productTypes: [ProductType] = isVariableProductsFeatureEnabled ?
        [.simple, .variable] : [.simple]
        let pagedProducts = try await productsRemote.loadProductsForPointOfSale(for: siteID, productTypes: productTypes, pageNumber: pageNumber)
        let products = pagedProducts.items

        if pageNumber != 1 && products.count == 0 {
            return .init(items: [], hasMorePages: false)
        }

        let eligibilityCriteria: [(Product) -> Bool] = [
            isNotVirtual,
            isNotDownloadable,
            hasPrice
        ]
        let filteredProducts = filterProducts(products: products, using: eligibilityCriteria)

        return .init(items: mapProductsToPOSItems(products: filteredProducts), hasMorePages: pagedProducts.hasMorePages)
    }

    public func providePointOfSaleVariationItems(for parentProduct: POSParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        let variations = try await variationRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProduct.productID,
                                          pageNumber: pageNumber)
        return .init(
            items: variations.compactMap({ variation in
                POSItem
                    .variation(.init(id: UUID(),
                                     // TODO-14702: variation name with ProductVariationFormatter
                                     name: "Variation \(variation.productVariationID)",
                                     formattedPrice: currencyFormatter.formatAmount(variation.price) ?? "-",
                                     productImageSource: variation.image?.src))
            }),
            // TODO-14696: pagination support for variations lists
            hasMorePages: false
        )
    }

    // Maps result to POSItem, and populate the output with:
    // - Formatted price based on store's currency settings.
    // - Product thumbnail, if any.
    private func mapProductsToPOSItems(products: [Product]) -> [POSItem] {
        return products.compactMap { product in
            let formattedPrice = currencyFormatter.formatAmount(product.price) ?? "-"
            let thumbnailSource = product.images.first?.src

            switch product.productType {
                case .simple:
                    return .simpleProduct(POSSimpleProduct(id: UUID(),
                                                           name: product.name,
                                                           formattedPrice: formattedPrice,
                                                           productImageSource: thumbnailSource,
                                                           productID: product.productID,
                                                           price: product.price))
                case .variable:
                    return .parentProduct(POSParentProduct(id: UUID(),
                                                           name: product.name,
                                                           productImageSource: thumbnailSource,
                                                           productID: product.productID,
                                                           type: .variable))
                default:
                    return nil
            }
        }
    }
}

private extension PointOfSaleItemService {
    func filterProducts(products: [Product], using criteria: [(Product) -> Bool]) -> [Product] {
        return products.filter { product in
            criteria.allSatisfy { $0(product) }
        }
    }

    func isNotVirtual(product: Product) -> Bool {
        !product.virtual
    }

    func isNotDownloadable(product: Product) -> Bool {
        !product.downloadable
    }

    func hasPrice(product: Product) -> Bool {
        !product.price.isEmpty
    }
}
