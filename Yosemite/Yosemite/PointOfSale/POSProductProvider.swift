import Foundation
import protocol Storage.StorageManagerType
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

/// Product provider for the Point of Sale feature
///
public final class POSProductProvider: POSItemProvider {
    private let storageManager: StorageManagerType
    private var siteID: Int64
    private var currencySettings: CurrencySettings

    public init(storageManager: StorageManagerType, siteID: Int64, currencySettings: CurrencySettings) {
        self.storageManager = storageManager
        self.siteID = siteID
        self.currencySettings = currencySettings
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
    public func providePointOfSaleItems() -> [POSItem] {
        var loadedProducts: [Product] = []

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
                // rather than having this declared implicitly:
                loadedProducts = productsResultsController.fetchedObjects.filter { $0.productType == .simple && $0.purchasable }
            }
        } catch {
            // TODO: Handle case for error when fetching products
            // https://github.com/woocommerce/woocommerce-ios/issues/12846
            DDLogError("Error fetching products from storage")
        }

        // 2. Map result to POSProduct, and populate the output already formatted with any applicable store settings
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return loadedProducts.map { product in
            let formattedPrice = currencyFormatter.formatAmount(product.price, with: currencySettings.currencyCode.rawValue) ?? "-"

            return POSProduct(itemID: UUID(),
                              productID: product.productID,
                              name: product.name,
                              price: formattedPrice)
        }
    }

    // TODO: Mechanism to reload/sync product data.
    // https://github.com/woocommerce/woocommerce-ios/issues/12837
}

// MARK: - PreviewProvider helpers
//
extension POSProductProvider {
    public static func provideProductForPreview() -> POSProduct {
        POSProduct(itemID: UUID(),
                   productID: 1,
                   name: "Product 1",
                   price: "$1.00")
    }

    public static func provideProductsForPreview() -> [POSProduct] {
        return [
            POSProduct(itemID: UUID(), productID: 1, name: "Product 1", price: "$1.00"),
            POSProduct(itemID: UUID(), productID: 2, name: "Product 2", price: "$2.00"),
            POSProduct(itemID: UUID(), productID: 3, name: "Product 3", price: "$3.00"),
            POSProduct(itemID: UUID(), productID: 4, name: "Product 4", price: "$4.00")
        ]
    }
}

/// Null product provider that acts as preview helper for the Point of Sale feature
///
public final class NullPOSProductProvider: POSItemProvider {

    public init() {}

    public func providePointOfSaleItems() -> [POSItem] {
        []
    }
}
