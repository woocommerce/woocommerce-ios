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
                isPublishedOrPrivateStatus,
                isNotVirtual,
                isNotDownloadable,
                hasPrice
            ]
            let filteredProducts = filterProducts(products: products, using: eligibilityCriteria)

            return mapProductsToPOSItems(products: filteredProducts)
        } catch {
            // TODO:
            // - Handle case for empty product list, or not empty but no eligible products
            // https://github.com/woocommerce/woocommerce-ios/issues/12815
            // https://github.com/woocommerce/woocommerce-ios/issues/12816
            // - Handle case for error when fetching products
            // https://github.com/woocommerce/woocommerce-ios/issues/12846
            DDLogError("No POS items")
            return []
        }
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

    // TODO: Mechanism to reload/sync product data.
    // https://github.com/woocommerce/woocommerce-ios/issues/12837
}

private extension POSProductProvider {
    func filterProducts(products: [Product], using criteria: [(Product) -> Bool]) -> [Product] {
        return products.filter { product in
            criteria.allSatisfy { $0(product) }
        }
    }

    func isPublishedOrPrivateStatus(product: Product) -> Bool {
        product.productStatus == .published || product.productStatus == .privateStatus
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
