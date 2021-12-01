import Yosemite
import protocol Storage.StorageManagerType

/// View model for `AddProduct`.
///
final class AddProductViewModel: ObservableObject {
    private let siteID: Int64
    private let storageManager: StorageManagerType

    /// All products that can be added to an order.
    /// Includes all non-variable products with published or private status. (Variable products to be added in a future milestone.)
    ///
    private var products: [Product] {
        return productsResultsController.fetchedObjects.filter { product in
            product.productType != .variable && ( product.productStatus == .publish || product.productStatus == .privateStatus )
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

        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching products: \(error)")
        }

        return resultsController
    }()

    init(siteID: Int64, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storageManager = storageManager
    }
}
