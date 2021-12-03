import Yosemite
import protocol Storage.StorageManagerType

/// View model for `AddProductToOrder`.
///
final class AddProductToOrderViewModel: ObservableObject {
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
    var productRows: [ProductRowViewModel] {
        products.map { .init(product: $0, canChangeQuantity: false) }
    }

    // MARK: Sync & Storage properties

    /// Current sync status; used to determine what list view to display.
    ///
    @Published private(set) var syncStatus: SyncStatus = .none

    /// Handles infinite scroll of product list.
    ///
    private let paginationTracker = PaginationTracker()

    /// Tracks if there are more products to sync from remote.
    ///
    @Published private(set) var hasMoreProducts: Bool = false

    /// View models of the ghost rows used during the loading process.
    ///
    var ghostRows: [ProductRowViewModel] {
        return Array(0..<6).map { index in
            ProductRowViewModel(product: sampleGhostProduct(id: index), canChangeQuantity: false)
        }
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

        configurePaginationTracker()
        configureProductsResultsController()
    }

    /// Sync next page of products from remote.
    ///
    func loadMoreProducts() {
        paginationTracker.ensureNextPageIsSynced()
    }
}

// MARK: - PaginationTrackerDelegate
extension AddProductToOrderViewModel: PaginationTrackerDelegate {
    /// Sync products from remote.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: SyncCompletion?) {
        let action = ProductAction.synchronizeProducts(siteID: siteID,
                                                       pageNumber: pageNumber,
                                                       pageSize: pageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       productCategory: nil,
                                                       sortOrder: .nameAscending,
                                                       shouldDeleteStoredProductsOnFirstPage: false) { [weak self] result in
            guard let self = self else { return }
            self.hasMoreProducts = true
            switch result {
            case .failure(let error):
                self.syncStatus = .error
                DDLogError("⛔️ Error synchronizing products during order creation: \(error)")
            case .success(let hasNextPage):
                self.updateProductsResultsController()
                if self.products.isNotEmpty {
                    self.syncStatus = .success
                } else {
                    self.syncStatus = .error
                }
                self.hasMoreProducts = hasNextPage
                onCompletion?(result)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - Configuration
private extension AddProductToOrderViewModel {
    /// Fetches products from storage. If there are no stored products, trigger a sync request.
    ///
    func configureProductsResultsController() {
        updateProductsResultsController()

        // Trigger a sync request if there are no products.
        guard products.isNotEmpty else {
            syncStatus = .firstPageLoad
            paginationTracker.syncFirstPage()
            return
        }

        syncStatus = .success
    }

    /// Fetches products from storage.
    ///
    func updateProductsResultsController() {
        do {
            try productsResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching products for new order: \(error)")
        }
    }

    func configurePaginationTracker() {
        paginationTracker.delegate = self
    }
}

// MARK: - Utils
extension AddProductToOrderViewModel {
    /// Represents possible statuses for syncing products
    ///
    enum SyncStatus {
        case firstPageLoad
        case success
        case error
        case none
    }

    /// Used for ghost list view while syncing
    ///
    private func sampleGhostProduct(id: Int64) -> Product {
        return Product().copy(productID: id,
                              name: "Love Ficus",
                              sku: "123456",
                              price: "20",
                              stockQuantity: 7,
                              stockStatusKey: "instock")
    }
}
