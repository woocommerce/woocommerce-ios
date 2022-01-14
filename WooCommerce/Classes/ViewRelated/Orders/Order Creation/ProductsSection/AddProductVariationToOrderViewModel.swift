import Yosemite
import protocol Storage.StorageManagerType

/// View model for `AddProductToOrder` with a list of product variations for a product.
///
final class AddProductVariationToOrderViewModel: AddProductToOrderViewModelProtocol {
    private let siteID: Int64

    /// Storage to fetch product variation list
    ///
    private let storageManager: StorageManagerType

    /// Stores to sync product variation list
    ///
    private let stores: StoresManager

    /// The product whose variations are listed
    ///
    private var product: Product

    /// All purchasable product variations for the product.
    ///
    private var productVariations: [ProductVariation] {
        productVariationsResultsController.fetchedObjects.filter { $0.purchasable }
    }

    /// View models for each product row
    ///
    var productRows: [ProductRowViewModel] {
        productVariations.map { .init(productVariation: $0, allAttributes: product.attributesForVariations, canChangeQuantity: false) }
    }

    // MARK: Sync & Storage properties

    /// Current sync status; used to determine what list view to display.
    ///
    @Published private(set) var syncStatus: AddProductToOrderSyncStatus?

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Tracks if the infinite scroll indicator should be displayed
    ///
    @Published private(set) var shouldShowScrollIndicator = false

    /// Product Variations Results Controller.
    ///
    private lazy var productVariationsResultsController: ResultsController<StorageProductVariation> = {
        let predicate = NSPredicate(format: "siteID == %lld AND productID == %lld", siteID, product.productID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductVariation.menuOrder, ascending: true)
        let resultsController = ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
        return resultsController
    }()

    init(siteID: Int64,
         product: Product,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.product = product
        self.storageManager = storageManager
        self.stores = stores

        configureSyncingCoordinator()
        configureProductVariationsResultsController()
    }

    /// Select a product variation to add to the order
    ///
    func selectProductOrVariation(_ productID: Int64) {
        // TODO: Add the selected product variation to the order
    }
}

// MARK: - SyncingCoordinatorDelegate & Sync Methods
extension AddProductVariationToOrderViewModel: SyncingCoordinatorDelegate {
    /// Sync product variations from remote.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)?) {
        transitionToSyncingState()
        let action = ProductVariationAction.synchronizeProductVariations(siteID: siteID,
                                                                         productID: product.productID,
                                                                         pageNumber: pageNumber,
                                                                         pageSize: pageSize) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                DDLogError("⛔️ Error synchronizing product variations during order creation: \(error)")
            } else {
                self.updateProductVariationsResultsController()
            }

            self.transitionToResultsUpdatedState()
            onCompletion?(error == nil)
        }
        stores.dispatch(action)
    }

    /// Sync first page of product variations from remote if needed.
    ///
    func syncFirstPage() {
        syncingCoordinator.synchronizeFirstPage()
    }

    /// Sync next page of product variations from remote.
    ///
    func syncNextPage() {
        let lastIndex = productVariationsResultsController.numberOfObjects - 1
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: lastIndex)
    }
}

// MARK: - Finite State Machine Management
private extension AddProductVariationToOrderViewModel {
    /// Update state for sync from remote.
    ///
    func transitionToSyncingState() {
        shouldShowScrollIndicator = true
        if productVariations.isEmpty {
            syncStatus = .firstPageSync
        }
    }

    /// Update state after sync is complete.
    ///
    func transitionToResultsUpdatedState() {
        shouldShowScrollIndicator = false
        syncStatus = productVariations.isNotEmpty ? .results: .empty
    }
}

// MARK: - Configuration
private extension AddProductVariationToOrderViewModel {
    /// Performs initial fetch from storage and updates sync status accordingly.
    ///
    func configureProductVariationsResultsController() {
        updateProductVariationsResultsController()
        transitionToResultsUpdatedState()
    }

    /// Fetches product variations from storage.
    ///
    func updateProductVariationsResultsController() {
        do {
            try productVariationsResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching product variations for new order: \(error)")
        }
    }

    /// Setup: Syncing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }
}
