import Yosemite
import protocol Storage.StorageManagerType

/// View model for `AddProductToOrder` with a list of products.
///
final class AddProductToOrderViewModel: AddProductToOrderViewModelProtocol {
    private let siteID: Int64

    /// Storage to fetch product list
    ///
    private let storageManager: StorageManagerType

    /// Stores to sync product list
    ///
    private let stores: StoresManager

    /// Product types excluded from the product list.
    /// For now, only non-variable product types are supported.
    ///
    private let excludedProductTypes: [ProductType] = [ProductType.variable]

    /// Product statuses included in the product list.
    /// Only published or private products can be added to an order.
    ///
    private let includedProductStatuses: [ProductStatus] = [ProductStatus.publish, ProductStatus.privateStatus]

    /// All products that can be added to an order.
    ///
    private var products: [Product] {
        return productsResultsController.fetchedObjects.filter {
            let hasValidProductType = !excludedProductTypes.contains( $0.productType )
            let hasValidProductStatus = includedProductStatuses.contains( $0.productStatus )
            return hasValidProductType && hasValidProductStatus
        }
    }

    /// View models for each product row
    ///
    var productRows: [ProductRowViewModel] {
        products.map { .init(product: $0, canChangeQuantity: false) }
    }

    /// Closure to be invoked when a product is selected
    ///
    let onProductSelected: ((Product) -> Void)?

    // MARK: Sync & Storage properties

    /// Current sync status; used to determine what list view to display.
    ///
    @Published private(set) var syncStatus: SyncStatus?

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Tracks if the infinite scroll indicator should be displayed
    ///
    @Published private(set) var shouldShowScrollIndicator = false

    /// Products Results Controller.
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
        return resultsController
    }()

    init(siteID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         onProductSelected: ((Product) -> Void)? = nil) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.stores = stores
        self.onProductSelected = onProductSelected

        configureSyncingCoordinator()
        configureProductsResultsController()
    }

    /// Select a product to add to the order
    ///
    func selectProductOrVariation(_ productID: Int64) {
        guard let selectedProduct = products.first(where: { $0.productID == productID }) else {
            return
        }
        onProductSelected?(selectedProduct)
    }
}

// MARK: - SyncingCoordinatorDelegate & Sync Methods
extension AddProductToOrderViewModel: SyncingCoordinatorDelegate {
    /// Sync products from remote.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)?) {
        transitionToSyncingState()
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

            switch result {
            case .success:
                self.updateProductsResultsController()
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing products during order creation: \(error)")
            }

            self.transitionToResultsUpdatedState()
            onCompletion?(result.isSuccess)
        }
        stores.dispatch(action)
    }

    /// Sync first page of products from remote if needed.
    ///
    func syncFirstPage() {
        syncingCoordinator.synchronizeFirstPage()
    }

    /// Sync next page of products from remote.
    ///
    func syncNextPage() {
        let lastIndex = productsResultsController.numberOfObjects - 1
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: lastIndex)
    }
}

// MARK: - Finite State Machine Management
private extension AddProductToOrderViewModel {
    /// Update state for sync from remote.
    ///
    func transitionToSyncingState() {
        shouldShowScrollIndicator = true
        if products.isEmpty {
            syncStatus = .firstPageSync
        }
    }

    /// Update state after sync is complete.
    ///
    func transitionToResultsUpdatedState() {
        shouldShowScrollIndicator = false
        syncStatus = products.isNotEmpty ? .results: .empty
    }
}

// MARK: - Configuration
private extension AddProductToOrderViewModel {
    /// Performs initial fetch from storage and updates sync status accordingly.
    ///
    func configureProductsResultsController() {
        updateProductsResultsController()
        transitionToResultsUpdatedState()
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

    /// Setup: Syncing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }
}
