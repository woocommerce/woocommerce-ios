import Yosemite
import protocol Storage.StorageManagerType

/// View model for `AddProduct`.
///
final class AddProductViewModel: ObservableObject {
    private let siteID: Int64
    private let storageManager: StorageManagerType

    /// Product types excluded from the product list.
    /// For now, only non-variable product types are supported.
    ///
    private let excludedProductTypeKeys: [String] = [ProductType.variable.rawValue]

    /// Product statuses included in the product list.
    /// Only published or private products can be added to an order.
    ///
    private let includedProductStatusKeys: [String] = [ProductStatus.publish.rawValue, ProductStatus.privateStatus.rawValue]

    /// All products that can be added to an order.
    ///
    private var products: [Product] {
        return productsResultsController.fetchedObjects
    }

    /// View models for each product row
    ///
    var productRowViewModels: [ProductRowViewModel] {
        products.map { .init(product: $0, canChangeQuantity: false) }
    }

    /// Products Results Controller.
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld AND statusKey IN %@ AND NOT(productTypeKey IN %@)",
                                    siteID, includedProductStatusKeys, excludedProductTypeKeys)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
        return resultsController
    }()

    init(siteID: Int64, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storageManager = storageManager

        configureProductsResultsController()
    }
}

// MARK: - Configuration
private extension AddProductViewModel {
    func configureProductsResultsController() {
        do {
            try productsResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching products for new order: \(error)")
        }
    }
}
