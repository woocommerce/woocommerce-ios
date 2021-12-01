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
    private let excludedProductTypes: [ProductType] = [.variable]

    /// Product statuses included in the product list.
    /// Only published or private products can be added to an order.
    ///
    private let includedProductStatuses: [ProductStatus] = [.publish, .privateStatus]

    /// All products that can be added to an order.
    ///
    private var products: [Product] {
        return productsResultsController.fetchedObjects.filter { product in
            !excludedProductTypes.contains(product.productType) && includedProductStatuses.contains(product.productStatus)
        }
    }

    /// View models for each product row
    ///
    var productRowViewModels: [ProductRowViewModel] {
        products.map { .init(product: $0, canChangeQuantity: false) }
    }

    /// Products Results Controller.
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
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
