import Foundation
import protocol Networking.Network
import class Networking.ProductsRemote
import class Networking.AlamofireNetwork
import protocol Storage.StorageManagerType
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

/// Product provider for the Point of Sale feature
///
public final class POSProductProvider: POSItemProvider {
    private let storageManager: StorageManagerType
    private var siteID: Int64
    private var currencySettings: CurrencySettings
    private let productsRemote: ProductsRemote

    public init(storageManager: StorageManagerType, siteID: Int64, currencySettings: CurrencySettings, network: Network) {
        self.storageManager = storageManager
        self.siteID = siteID
        self.currencySettings = currencySettings
        self.productsRemote = ProductsRemote(network: network)
    }

    public convenience init(storageManager: StorageManagerType,
                     siteID: Int64,
                     currencySettings: CurrencySettings,
                     credentials: Credentials?) {
        self.init(storageManager: storageManager,
                  siteID: siteID,
                  currencySettings: currencySettings,
                  network: AlamofireNetwork(credentials: credentials))
    }

    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortedBy: [descriptor])
        return resultsController
    }()

    public func providePointOfSaleItemsFromNetwork() async throws -> [POSItem] {
        do {
            let products = try await productsRemote.loadAllSimpleProductsForPointOfSale(for: siteID)
            debugPrint("\(products)")
            return mapProductsToPOSItems(products: products)
        }
    }

    // Maps result to POSProduct, and populate the output with:
    // - Formatted price based on store's currency settings.
    // - Product categories, if any.
    // - Product thumbnail, if any.
    private func mapProductsToPOSItems(products: [Product]) -> [POSItem] {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return products.map { product in
            let formattedPrice = currencyFormatter.formatAmount(product.price, with: currencySettings.currencyCode.rawValue) ?? "-"
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

    /// Provides a`[POSProduct]`array by mapping  simple, purchasable-only Products from storage
    ///
    public func providePointOfSaleItemsFromStorage() -> [POSItem] {
        var loadedProducts: [Product] = []

        // Fetch products from storage, and filter them by `purchasable` and `simple`
        do {
            try productsResultsController.performFetch()
            if productsResultsController.fetchedObjects.isEmpty {
                // TODO: Handle case for empty product list, or not empty but no eligible products
                // https://github.com/woocommerce/woocommerce-ios/issues/12815
                // https://github.com/woocommerce/woocommerce-ios/issues/12816
                DDLogWarn("No products eligible for POS, or empty storage.")
            } else {
                // Ideally we should handle the filtering through a policy that can be easily modified,
                // rather than having this declared implicitly:
                loadedProducts = productsResultsController.fetchedObjects.filter { $0.productType == .simple && $0.purchasable }
            }
        } catch {
            // TODO: Handle case for error when fetching products
            // https://github.com/woocommerce/woocommerce-ios/issues/12846
            DDLogError("Error fetching products from storage")
        }
        return mapProductsToPOSItems(products: loadedProducts)
    }

    // TODO: Mechanism to reload/sync product data.
    // https://github.com/woocommerce/woocommerce-ios/issues/12837
}
