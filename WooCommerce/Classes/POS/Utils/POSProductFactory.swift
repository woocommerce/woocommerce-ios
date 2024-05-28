import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import class WooFoundation.CurrencySettings

/// Temporary fake product factory
///
final class POSProductFactory {
    private let storageManager: StorageManagerType = ServiceLocator.storageManager
    private var siteID: Int64 { ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0 }
    private var currencySettings: CurrencySettings = ServiceLocator.currencySettings

    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortedBy: [descriptor])
        return resultsController
    }()

    static func makeProduct(currencySettings: CurrencySettings = ServiceLocator.currencySettings) -> POSProduct {
        POSProduct(itemID: UUID(),
                   productID: 1,
                   name: "Product 1",
                   price: "1.00",
                   stockQuantity: 10,
                   currencySettings: currencySettings)
    }

    static func makeFakeProducts(currencySettings: CurrencySettings = ServiceLocator.currencySettings) -> [POSProduct] {
        return [
            POSProduct(itemID: UUID(), productID: 1, name: "Product 1", price: "1.00", stockQuantity: 10, currencySettings: currencySettings),
            POSProduct(itemID: UUID(), productID: 2, name: "Product 2", price: "2.00", stockQuantity: 10, currencySettings: currencySettings),
            POSProduct(itemID: UUID(), productID: 3, name: "Product 3", price: "3.00", stockQuantity: 10, currencySettings: currencySettings),
            POSProduct(itemID: UUID(), productID: 4, name: "Product 4", price: "4.00", stockQuantity: 0, currencySettings: currencySettings),
            ]
    }

    /// Returns an array of [PosProduct] mapped from [Yosemite.Product]
    ///
    func makePointOfSaleProducts() -> [POSProduct] {
        // 1. Load App products
        var loadedProducts: [Product] = []
        var pointOfSaleProducts: [POSProduct] = []

        do {
            try productsResultsController.performFetch()
            // TODO: Handle filtering through a policy
            loadedProducts = productsResultsController.fetchedObjects.filter { $0.productType == .simple }
        } catch {
            // TODO: Handle
            fatalError()
        }

        // 2. Map from App product to POS product
        for product in loadedProducts {
            let posProduct = POSProduct(itemID: UUID(),
                                        productID: product.productID,
                                        name: product.name,
                                        price: product.price,
                                        stockQuantity: product.stockQuantity?.intValue ?? 0, // TODO: Remove stock usage
                                        currencySettings: currencySettings)
            pointOfSaleProducts.append(posProduct)
        }

        // 4. Output
        return pointOfSaleProducts
    }

    // TODO: Mechanism to reload/sync product data.
    // https://github.com/woocommerce/woocommerce-ios/issues/12837
}
