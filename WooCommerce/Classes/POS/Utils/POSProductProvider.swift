import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import class WooFoundation.CurrencySettings

/// Product provider for the Point of Sale feature
///
final class POSProductProvider {
    private let storageManager: StorageManagerType
    private var siteID: Int64
    private var currencySettings: CurrencySettings

    init() {
        self.storageManager = ServiceLocator.storageManager
        self.siteID = ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
        self.currencySettings = ServiceLocator.currencySettings
    }

    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortedBy: [descriptor])
        return resultsController
    }()

    /// Provides a`[POSProduct]`array by mapping  simple, purchasable-only Products from storage
    ///
    func providePointOfSaleProducts() -> [POSProduct] {
        var loadedProducts: [Product] = []
        var pointOfSaleProducts: [POSProduct] = []

        // 1. Fetch products from storage, and filter them by `purchasable` and `simple`
        do {
            try productsResultsController.performFetch()
            if productsResultsController.fetchedObjects.isEmpty {
                // TODO: Handle case for empty product list, or not empty but no eligible products
                // https://github.com/woocommerce/woocommerce-ios/issues/12815
                // https://github.com/woocommerce/woocommerce-ios/issues/12816
                DDLogWarn("No products eligible for POS, or empty storage.")
            } else {
                // Ideally we should handle the filtering through a policy that can be easily modified,
                // rather than having this declared implicitely:
                loadedProducts = productsResultsController.fetchedObjects.filter { $0.productType == .simple && $0.purchasable }
            }
        } catch {
            // TODO: Handle case for error when fetching products
            // https://github.com/woocommerce/woocommerce-ios/issues/12846
            DDLogError("Error fetching products from storage")
        }

        // 2. Map result to POSProduct and populate the output
        for product in loadedProducts {
            let posProduct = POSProduct(itemID: UUID(),
                                        productID: product.productID,
                                        name: product.name,
                                        price: product.price,
                                        currencySettings: currencySettings)
            pointOfSaleProducts.append(posProduct)
        }
        return pointOfSaleProducts
    }

    // TODO: Mechanism to reload/sync product data.
    // https://github.com/woocommerce/woocommerce-ios/issues/12837
}

// MARK: - PreviewProvider helpers
//
extension POSProductProvider {
    static func provideProductForPreview(currencySettings: CurrencySettings = ServiceLocator.currencySettings) -> POSProduct {
        POSProduct(itemID: UUID(),
                   productID: 1,
                   name: "Product 1",
                   price: "1.00",
                   currencySettings: currencySettings)
    }

    static func provideProductsForPreview(currencySettings: CurrencySettings = ServiceLocator.currencySettings) -> [POSProduct] {
        return [
            POSProduct(itemID: UUID(), productID: 1, name: "Product 1", price: "1.00", currencySettings: currencySettings),
            POSProduct(itemID: UUID(), productID: 2, name: "Product 2", price: "2.00", currencySettings: currencySettings),
            POSProduct(itemID: UUID(), productID: 3, name: "Product 3", price: "3.00", currencySettings: currencySettings),
            POSProduct(itemID: UUID(), productID: 4, name: "Product 4", price: "4.00", currencySettings: currencySettings),
        ]
    }
}
