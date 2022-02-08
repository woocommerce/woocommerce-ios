import Yosemite
import protocol Storage.StorageManagerType
import Combine
import Foundation

/// View model for `AddProductToOrder`.
///
final class AddProductToOrderViewModel: ObservableObject {
    private let siteID: Int64

    /// Storage to fetch product list
    ///
    private let storageManager: StorageManagerType

    /// Stores to sync product list
    ///
    private let stores: StoresManager

    /// Store for publishers subscriptions
    ///
    private var subscriptions = Set<AnyCancellable>()

    /// Trigger to perform any one time setups.
    ///
    let onLoadTrigger: PassthroughSubject<Void, Never> = PassthroughSubject()

    /// All products that can be added to an order.
    ///
    private var products: [Product] {
        productsResultsController.fetchedObjects.filter { $0.purchasable }
    }

    /// View models for each product row
    ///
    var productRows: [ProductRowViewModel] {
        products.map { .init(product: $0, canChangeQuantity: false) }
    }

    /// Closure to be invoked when a product is selected
    ///
    let onProductSelected: ((Product) -> Void)?

    /// Closure to be invoked when a product variation is selected
    ///
    let onVariationSelected: ((ProductVariation) -> Void)?

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

    /// View models of the ghost rows used during the loading process.
    ///
    var ghostRows: [ProductRowViewModel] {
        return Array(0..<6).map { index in
            ghostProductRow(id: index)
        }
    }

    /// Products Results Controller.
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
        return resultsController
    }()

    /// Predicate for the results controller.
    ///
    private lazy var resultsPredicate: NSPredicate? = {
        productsResultsController.predicate
    }()

    /// Current search term entered by the user.
    /// Each update will trigger a remote product search and sync.
    @Published var searchTerm: String = ""

    init(siteID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         onProductSelected: ((Product) -> Void)? = nil,
         onVariationSelected: ((ProductVariation) -> Void)? = nil) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.stores = stores
        self.onProductSelected = onProductSelected
        self.onVariationSelected = onVariationSelected

        configureSyncingCoordinator()
        configureProductsResultsController()
        configureFirstPageLoad()
        configureProductSearch()
    }

    /// Select a product to add to the order
    ///
    func selectProduct(_ productID: Int64) {
        guard let selectedProduct = products.first(where: { $0.productID == productID }) else {
            return
        }
        onProductSelected?(selectedProduct)
    }

    /// Get the view model for a list of product variations to add to the order
    ///
    func getVariationsViewModel(for productID: Int64) -> AddProductVariationToOrderViewModel? {
        guard let variableProduct = products.first(where: { $0.productID == productID }) else {
            return nil
        }
        return AddProductVariationToOrderViewModel(siteID: siteID, product: variableProduct, onVariationSelected: onVariationSelected)
    }
}

// MARK: - SyncingCoordinatorDelegate & Sync Methods
extension AddProductToOrderViewModel: SyncingCoordinatorDelegate {
    /// Sync products from remote.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)?) {
        transitionToSyncingState()

        if let searchTerm = reason, searchTerm.isNotEmpty {
            searchProducts(siteID: siteID, keyword: searchTerm, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        } else {
            syncProducts(pageNumber: pageNumber, pageSize: pageSize, reason: reason, onCompletion: onCompletion)
        }
    }

    /// Sync all products from remote.
    ///
    private func syncProducts(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)?) {
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

    /// Sync products matching a given keyword.
    ///
    private func searchProducts(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = ProductAction.searchProducts(siteID: siteID,
                                                  keyword: keyword,
                                                  pageNumber: pageNumber,
                                                  pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.updateProductsResultsController()
            case .failure(let error):
                DDLogError("⛔️ Error searching products during order creation: \(error)")
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

    /// Performs initial sync on first page load
    ///
    func configureFirstPageLoad() {
        // Listen only to the first emitted event.
        onLoadTrigger.first()
            .sink { [weak self] in
                guard let self = self else { return }
                self.syncFirstPage()
            }
            .store(in: &subscriptions)
    }

    /// Updates the product results predicate & triggers a new sync when search term changes
    ///
    func configureProductSearch() {
        $searchTerm
            .dropFirst() // Drop initial value
            .removeDuplicates()
            .sink { [weak self] newSearchTerm in
                guard let self = self else { return }

                if newSearchTerm.isNotEmpty {
                    // When the search query changes, also includes the original results predicate in addition to the search keyword.
                    let searchResultsPredicate = NSPredicate(format: "ANY searchResults.keyword = %@", newSearchTerm)
                    let subpredicates = [self.resultsPredicate].compactMap { $0 } + [searchResultsPredicate]
                    self.productsResultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
                } else {
                    // Resets the results to the full product list when there is no search query.
                    self.productsResultsController.predicate = self.resultsPredicate
                }

                self.syncingCoordinator.resynchronize(reason: newSearchTerm)
            }.store(in: &subscriptions)
    }
}

// MARK: - Utils
extension AddProductToOrderViewModel {
    /// Represents possible statuses for syncing products
    ///
    enum SyncStatus {
        case firstPageSync
        case results
        case empty
    }

    /// Used for ghost list view while syncing
    ///
    private func ghostProductRow(id: Int64) -> ProductRowViewModel {
        ProductRowViewModel(productOrVariationID: id,
                            name: "Ghost Product",
                            sku: nil,
                            price: "20",
                            stockStatusKey: ProductStockStatus.inStock.rawValue,
                            stockQuantity: 1,
                            manageStock: false,
                            canChangeQuantity: false,
                            imageURL: nil)
    }
}
