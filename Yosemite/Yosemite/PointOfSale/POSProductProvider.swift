import Foundation
import protocol Networking.Network
import class Networking.ProductsRemote
import class Networking.AlamofireNetwork
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

/// Product provider for the Point of Sale feature
///
public final class POSProductProvider: POSItemProvider {
    private var siteID: Int64
    private var currencySettings: CurrencySettings
    private let productsRemote: ProductsRemote

    public init(siteID: Int64, currencySettings: CurrencySettings, network: Network) {
        self.siteID = siteID
        self.currencySettings = currencySettings
        self.productsRemote = ProductsRemote(network: network)
    }

    public convenience init(siteID: Int64,
                            currencySettings: CurrencySettings,
                            credentials: Credentials?) {
        self.init(siteID: siteID,
                  currencySettings: currencySettings,
                  network: AlamofireNetwork(credentials: credentials))
    }

    public func providePointOfSaleItems() async throws -> [POSItem] {
        do {
            let products = try await productsRemote.loadAllSimpleProductsForPointOfSale(for: siteID)

            let eligibilityCriteria: [(Product) -> Bool] = [
                isNotVirtual,
                isNotDownloadable,
                hasPrice
            ]
            let filteredProducts = filterProducts(products: products, using: eligibilityCriteria)

            return mapProductsToPOSItems(products: filteredProducts)
        } catch {
            DDLogError("Failed to retrieve products. Error: \(error)")
            throw POSProductProviderError.requestFailed
        }
    }

    enum POSProductProviderError: Error {
        case requestFailed
    }

    // Maps result to POSProduct, and populate the output with:
    // - Formatted price based on store's currency settings.
    // - Product categories, if any.
    // - Product thumbnail, if any.
    private func mapProductsToPOSItems(products: [Product]) -> [POSItem] {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return products.map { product in
            let formattedPrice = currencyFormatter.formatAmount(product.price) ?? "-"
            let thumbnailSource = product.images.first?.src
            let productCategories = product.categories.map { $0.name }

            return POSProduct(itemID: UUID(),
                              productID: product.productID,
                              name: product.name,
                              price: product.price,
                              formattedPrice: formattedPrice,
                              itemCategories: productCategories,
                              productImageSource: thumbnailSource,
                              productType: product.productType)
        }
    }
}

private extension POSProductProvider {
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
