import Yosemite
import protocol Storage.StorageManagerType
import Combine
import Foundation
import WooFoundation

struct ProductsSectionViewModel {
    let title: String?
    let productRows: [ProductRowViewModel]
}

struct ProductSelectorSection {
    let type: ProductSelectorSectionType
    let products: [Product]
}

enum ProductSelectorSectionType {
    // Show most popular products, that is, most sold
    case mostPopular
    // Show last sold
    case lastSold
    // Show products that are not popular or last sold
    case restOfProducts
    // Show all products in one section without title
    case allProducts

    var title: String? {
        switch self {
        case .mostPopular:
            return ProductSelectorViewModel.Localization.popularProductsSectionTitle
        case .lastSold:
            return ProductSelectorViewModel.Localization.lastSoldProductsSectionTitle
        case .restOfProducts:
            return ProductSelectorViewModel.Localization.productsSectionTitle
        case .allProducts:
            return nil
        }
    }
}

/// View model for `ProductSelectorView`.
///
final class ProductSelectorViewModel: ObservableObject {
    private let siteID: Int64

    /// Storage to fetch product list
    ///
    private let storageManager: StorageManagerType

    /// Stores to sync product list
    ///
    private let stores: StoresManager

    /// Analytics service
    ///
    private let analytics: Analytics

    /// Store for publishers subscriptions
    ///
    private var subscriptions = Set<AnyCancellable>()

    /// Trigger to perform any one time setups.
    ///
    let onLoadTrigger: PassthroughSubject<Void, Never> = PassthroughSubject()

    /// View model for the filter list.
    ///
    var filterListViewModel: FilterProductListViewModel {
        FilterProductListViewModel(filters: filtersSubject.value, siteID: siteID)
    }

    /// Selected filters for the product list
    ///
    private let filtersSubject = CurrentValueSubject<FilterProductListViewModel.Filters, Never>(.init())

    /// Title of the filter button, should be updated with number of active filters.
    ///
    @Published var filterButtonTitle: String = Localization.filterButtonWithoutActiveFilters

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var notice: Notice?

    /// All products that can be added to an order.
    ///
    private var products: [Product] {
        sections
            .map { $0.products }
            .flatMap { $0 }
    }

    /// Ids of those products that were most or last sold among the cached orders
    ///
    private var topProductsFromCachedOrders: ProductSelectorTopProducts = ProductSelectorTopProducts.empty

    private let tracker: ProductSelectorViewModelTracker

    /// Whether we should show the products split by sections
    ///
    private var shouldShowSections: Bool {
        searchTerm.isEmpty && filtersSubject.value.numberOfActiveFilters == 0
    }

    /// Sections containing products
    ///
    @Published private(set) var sections: [ProductSelectorSection] = []

    /// View Models for the sections
    /// 
    @Published var productsSectionViewModels: [ProductsSectionViewModel] = []

    /// Determines if multiple item selection is supported.
    ///
    let supportsMultipleSelection: Bool

    /// Determines if it is possible to toggle all variation items upon selection
    ///
    let toggleAllVariationsOnSelection: Bool

    /// Closure to be invoked when a product is selected or deselected
    ///
    private let onProductSelectionStateChanged: ((Product) -> Void)?

    /// Closure to be invoked when a product variation is selected or deselected
    ///
    private let onVariationSelectionStateChanged: ((ProductVariation, Product) -> Void)?

    /// Closure to be invoked when multiple selection is completed
    ///
    private let onMultipleSelectionCompleted: (([Int64]) -> Void)?

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
        let descriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
        return resultsController
    }()

    /// Predicate for the results controller.
    ///
    private var resultsPredicate: NSPredicate? {
        productsResultsController.predicate
    }

    /// Current search term entered by the user.
    /// Each update will trigger a remote product search and sync.
    @Published var searchTerm: String = ""

    /// All selected products if the selector supports multiple selections.
    ///
    @Published private var selectedProductIDs: [Int64] = []

    /// All selected product variations if the selector supports multiple selections.
    ///
    @Published private var selectedProductVariationIDs: [Int64] = []

    var totalSelectedItemsCount: Int {
        selectedProductIDs.count + selectedProductVariationIDs.count
    }

    /// IDs of selected products and variations from initializer.
    /// This is mutable since we want to cancel the setup for any item that is unselected manually.
    ///
    private var initialSelectedItems: [Int64]

    /// Whether the product list should contains only purchasable items.
    ///
    private let purchasableItemsOnly: Bool

    /// Closure to be invoked when "Clear Selection" is called.
    ///
    private let onAllSelectionsCleared: (() -> Void)?

    /// Closure to be invoked when variations "Clear Selection" is called.
    ///
    private let onSelectedVariationsCleared: (() -> Void)?

    private let onCloseButtonTapped: (() -> Void)?

    /// Initializer for single selection
    ///
    init(siteID: Int64,
         selectedItemIDs: [Int64] = [],
         purchasableItemsOnly: Bool = false,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         supportsMultipleSelection: Bool = false,
         toggleAllVariationsOnSelection: Bool = true,
         topProductsProvider: ProductSelectorTopProductsProviderProtocol? = nil,
         onProductSelectionStateChanged: ((Product) -> Void)? = nil,
         onVariationSelectionStateChanged: ((ProductVariation, Product) -> Void)? = nil,
         onMultipleSelectionCompleted: (([Int64]) -> Void)? = nil,
         onAllSelectionsCleared: (() -> Void)? = nil,
         onSelectedVariationsCleared: (() -> Void)? = nil,
         onCloseButtonTapped: (() -> Void)? = nil) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.stores = stores
        self.analytics = analytics
        self.supportsMultipleSelection = supportsMultipleSelection
        self.toggleAllVariationsOnSelection = toggleAllVariationsOnSelection
        self.onProductSelectionStateChanged = onProductSelectionStateChanged
        self.onVariationSelectionStateChanged = onVariationSelectionStateChanged
        self.onMultipleSelectionCompleted = onMultipleSelectionCompleted
        self.initialSelectedItems = selectedItemIDs
        self.purchasableItemsOnly = purchasableItemsOnly
        self.onAllSelectionsCleared = onAllSelectionsCleared
        self.onSelectedVariationsCleared = onSelectedVariationsCleared
        self.onCloseButtonTapped = onCloseButtonTapped
        tracker = ProductSelectorViewModelTracker(analytics: analytics, trackProductsSource: topProductsProvider != nil)

        topProductsFromCachedOrders = topProductsProvider?.provideTopProducts(siteID: siteID) ?? .empty
        tracker.viewModel = self

        configureSyncingCoordinator()
        refreshDataAndSync()
        configureFirstPageLoad()
        synchronizeProductFilterSearch()
    }

    /// Initializer for multiple selections
    ///
    init(siteID: Int64,
         selectedItemIDs: [Int64],
         purchasableItemsOnly: Bool = false,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         supportsMultipleSelection: Bool = false,
         toggleAllVariationsOnSelection: Bool = true,
         topProductsProvider: ProductSelectorTopProductsProviderProtocol? = nil,
         onMultipleSelectionCompleted: (([Int64]) -> Void)? = nil,
         onAllSelectionsCleared: (() -> Void)? = nil,
         onSelectedVariationsCleared: (() -> Void)? = nil,
         onCloseButtonTapped: (() -> Void)? = nil) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.stores = stores
        self.analytics = analytics
        self.supportsMultipleSelection = supportsMultipleSelection
        self.toggleAllVariationsOnSelection = toggleAllVariationsOnSelection
        self.onProductSelectionStateChanged = nil
        self.onVariationSelectionStateChanged = nil
        self.onMultipleSelectionCompleted = onMultipleSelectionCompleted
        self.initialSelectedItems = selectedItemIDs
        self.purchasableItemsOnly = purchasableItemsOnly
        self.onAllSelectionsCleared = onAllSelectionsCleared
        self.onSelectedVariationsCleared = onSelectedVariationsCleared
        self.onCloseButtonTapped = onCloseButtonTapped
        self.tracker = ProductSelectorViewModelTracker(analytics: analytics, trackProductsSource: topProductsProvider != nil)

        topProductsFromCachedOrders = topProductsProvider?.provideTopProducts(siteID: siteID) ?? .empty
        tracker.viewModel = self

        configureSyncingCoordinator()
        refreshDataAndSync()
        configureFirstPageLoad()
        synchronizeProductFilterSearch()
    }

    /// Selects or unselects a product to add to the order
    ///
    func changeSelectionStateForProduct(with productID: Int64) {
        guard let selectedProduct = products.first(where: { $0.productID == productID }) else {
            return
        }

        tracker.updateTrackingSourceAfterSelectionStateChangedForProduct(with: productID)

        guard let onProductSelectionStateChanged else {
            toggleSelection(productID: productID)
            return
        }
        guard supportsMultipleSelection else {
            // The selector supports single selection only
            onProductSelectionStateChanged(selectedProduct)
            return
        }
        // The selector supports multiple selection. Toggles the item, and triggers the selection
        toggleSelection(productID: productID)
        onProductSelectionStateChanged(selectedProduct)
    }

    func changeSelectionStateForVariation(with id: Int64, productID: Int64) {
        getVariationsViewModel(for: productID)?.changeSelectionStateForVariation(with: id)

        if selectedProductVariationIDs.contains(id) {
            selectedProductVariationIDs = selectedProductVariationIDs.filter { $0 != id }
        } else {
            selectedProductVariationIDs.append(id)
        }
    }

    /// Get the view model for a list of product variations to add to the order
    ///
    func getVariationsViewModel(for productID: Int64) -> ProductVariationSelectorViewModel? {
        guard let variableProduct = products.first(where: { $0.productID == productID }), variableProduct.variations.isNotEmpty else {
            return nil
        }
        let selectedItems = selectedProductVariationIDs.filter { variableProduct.variations.contains($0) }
        return ProductVariationSelectorViewModel(siteID: siteID,
                                                 product: variableProduct,
                                                 selectedProductVariationIDs: selectedItems,
                                                 purchasableItemsOnly: purchasableItemsOnly,
                                                 supportsMultipleSelection: supportsMultipleSelection,
                                                 onVariationSelectionStateChanged: onVariationSelectionStateChanged,
                                                 onSelectionsCleared: onSelectedVariationsCleared)
    }

    /// Clears the current search term and filters to display the full product list.
    ///
    func clearSearchAndFilters() {
        searchTerm = ""
        filtersSubject.send(.init())
    }

    /// Updates selected variation list based on the new selected IDs
    ///
    func updateSelectedVariations(productID: Int64, selectedVariationIDs: [Int64]) {
        guard let variableProduct = products.first(where: { $0.productID == productID }),
              variableProduct.variations.isNotEmpty else {
            return
        }
        // remove items that exist in the initial list
        initialSelectedItems.removeAll { selectedVariationIDs.contains($0) }
        // remove all previous selected variations
        selectedProductVariationIDs.removeAll(where: { variableProduct.variations.contains($0) })
        // append new selected IDs
        selectedProductVariationIDs.append(contentsOf: selectedVariationIDs)

        tracker.updateTrackingSourceAfterSelectionStateChangedForProduct(with: productID, selectedVariationIDs: selectedVariationIDs)
    }

    /// Select all variations for a given product
    ///
    func toggleSelectionForAllVariations(of productID: Int64) {
        guard toggleAllVariationsOnSelection else {
            return
        }
        guard let variableProduct = products.first(where: { $0.productID == productID }),
              variableProduct.variations.isNotEmpty else {
            return
        }
        let selectedIDs: [Int64]
        let intersection = Set(variableProduct.variations).intersection(Set(selectedProductVariationIDs))
        if intersection.count == variableProduct.variations.count {
            // if all variation is currently selected, deselect them all
            selectedIDs = []
        } else {
            // otherwise select all variations for the product
            selectedIDs = variableProduct.variations
        }

        updateSelectedVariations(productID: productID, selectedVariationIDs: selectedIDs)
    }

    /// Triggers completion closure when the multiple selection completes.
    ///
    func completeMultipleSelection() {
        let allIDs = selectedProductIDs + selectedProductVariationIDs
        tracker.trackConfirmButtonTapped(with: allIDs.count)
        onMultipleSelectionCompleted?(allIDs)
    }

    /// Triggers completion closure when the close button is tapped
    ///
    func closeButtonTapped() {
        onCloseButtonTapped?()
    }

    /// Unselect all items.
    ///
    func clearSelection() {
        initialSelectedItems = []
        selectedProductIDs = []
        selectedProductVariationIDs = []

        onAllSelectionsCleared?()
    }
}

// MARK: - SyncingCoordinatorDelegate & Sync Methods
extension ProductSelectorViewModel: SyncingCoordinatorDelegate {
    /// Sync products from remote.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)?) {
        transitionToSyncingState()

        if searchTerm.isNotEmpty {
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
                                                       stockStatus: filtersSubject.value.stockStatus,
                                                       productStatus: filtersSubject.value.productStatus,
                                                       productType: filtersSubject.value.productType,
                                                       productCategory: filtersSubject.value.productCategory,
                                                       sortOrder: .nameAscending,
                                                       shouldDeleteStoredProductsOnFirstPage: true) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.reloadData()
            case .failure(let error):
                self.notice = NoticeFactory.productSyncNotice() { [weak self] in
                    self?.sync(pageNumber: pageNumber, pageSize: pageSize, onCompletion: nil)
                }
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
        searchProductsInCacheIfPossible(siteID: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize)

        let action = ProductAction.searchProducts(siteID: siteID,
                                                  keyword: keyword,
                                                  pageNumber: pageNumber,
                                                  pageSize: pageSize,
                                                  stockStatus: filtersSubject.value.stockStatus,
                                                  productStatus: filtersSubject.value.productStatus,
                                                  productType: filtersSubject.value.productType,
                                                  productCategory: filtersSubject.value.productCategory) { [weak self] result in
            // Don't continue if this isn't the latest search.
            guard let self = self, keyword == self.searchTerm else {
                return
            }

            switch result {
            case .success:
                self.reloadData()
            case .failure(let error):
                self.notice = NoticeFactory.productSearchNotice() { [weak self] in
                    self?.searchProducts(siteID: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize, onCompletion: nil)
                }
                DDLogError("⛔️ Error searching products during order creation: \(error)")
            }

            self.transitionToResultsUpdatedState()
            onCompletion?(result.isSuccess)
        }

        stores.dispatch(action)
    }

    private func searchProductsInCacheIfPossible(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int) {
        // At the moment local search supports neither filters nor pagination
        guard filtersSubject.value.numberOfActiveFilters == 0,
              pageNumber == 1 else {
            return
        }

        let action = ProductAction.searchProductsInCache(siteID: siteID, keyword: keyword, pageSize: pageSize) { [weak self ] thereAreCachedResults in
            guard let self = self,
                  keyword == self.searchTerm else {
                return
            }
            if thereAreCachedResults {
                self.reloadData()
                self.transitionToResultsUpdatedState()
            }
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

    /// Updates the selected filters for the product list
    ///
    func updateFilters(_ filters: FilterProductListViewModel.Criteria) {
        filtersSubject.send(filters)
    }
}

// MARK: - Finite State Machine Management
private extension ProductSelectorViewModel {
    /// Update state for sync from remote.
    ///
    func transitionToSyncingState() {
        shouldShowScrollIndicator = true
        notice = nil
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
private extension ProductSelectorViewModel {
    /// Reloads data and triggers the UI load
    ///
    func refreshDataAndSync() {
        reloadData()
        transitionToResultsUpdatedState()
    }

    /// Reloads the data from the storage and composes sections and selections.
    ///
    func reloadData() {
            do {
                try productsResultsController.performFetch()
                var loadedProducts: [Product] = []
                if purchasableItemsOnly {
                    loadedProducts = productsResultsController.fetchedObjects.filter { $0.purchasable }
                } else {
                    loadedProducts = productsResultsController.fetchedObjects
                }

                createSectionsAddingTopProductsIfRequired(from: loadedProducts)
                updateSelectionsFromInitialSelectedItems()
                observeSelections()
            } catch {
                DDLogError("⛔️ Error fetching products for new order: \(error)")
            }
    }

    func createSectionsAddingTopProductsIfRequired(from loadedProducts: [Product]) {
        let popularProducts = Array(filterProductsFromSortedIdsArray(originalProducts: loadedProducts,
                                                                     productsIds: topProductsFromCachedOrders.popularProductsIds)
            .prefix(Constants.topSectionsMaxLength))

        guard popularProducts.isNotEmpty,
              shouldShowSections else {
            sections = [ProductSelectorSection(type: .allProducts, products: loadedProducts)]
            return
        }

        sections = [ProductSelectorSection(type: .mostPopular, products: popularProducts)]

        let lastSoldProducts = filterProductsFromSortedIdsArray(originalProducts: loadedProducts, productsIds: topProductsFromCachedOrders.lastSoldProductsIds)
        let filteredLastSoldProducts = Array(removeAlreadyAddedProducts(from: lastSoldProducts).prefix(Constants.topSectionsMaxLength))

        appendSectionIfNotEmpty(type: .lastSold, products: filteredLastSoldProducts)
        appendSectionIfNotEmpty(type: .restOfProducts, products: loadedProducts)
    }

    func filterProductsFromSortedIdsArray(originalProducts: [Product], productsIds: [Int64]) -> [Product] {
        productsIds
            .compactMap { productId in
                originalProducts.first(where: {
                    $0.productID == productId
                })
            }
    }

    func removeAlreadyAddedProducts(from newProducts: [Product]) -> [Product] {
        newProducts
            .filter { product in
                // We don't use `contains` here because of performance reasons,
                // as we don't need to check all the Product properties as the Equatable synthesized function would do.
                // Furthermore, with the latter can get different properties (e.g arrays from set that have different order) from the same product.
                products.first(where: { $0.productID == product.productID }) == nil
        }
    }

    func appendSectionIfNotEmpty(type: ProductSelectorSectionType, products: [Product]) {
        guard products.isNotEmpty else {
            return
        }

        sections.append(ProductSelectorSection(type: type, products: products))
    }

    func updatePredicate(searchTerm: String, filters: FilterProductListViewModel.Filters) {
        productsResultsController.updatePredicate(siteID: siteID,
                                                  stockStatus: filters.stockStatus,
                                                  productStatus: filters.productStatus,
                                                  productType: filters.productType)
        if searchTerm.isNotEmpty {
            // When the search query changes, also includes the original results predicate in addition to the search keyword.
            let searchResultsPredicate = NSPredicate(format: "ANY searchResults.keyword = %@", searchTerm)
            let subpredicates = [resultsPredicate, searchResultsPredicate].compactMap { $0 }
            productsResultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        } else {
            // Resets the results to the full product list when there is no search query.
            productsResultsController.predicate = resultsPredicate
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
    func synchronizeProductFilterSearch() {
        let searchTermPublisher = $searchTerm
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)

        let filtersPublisher = filtersSubject.removeDuplicates()

        searchTermPublisher.combineLatest(filtersPublisher)
            .sink { [weak self] searchTerm, filtersSubject in
                guard let self = self else { return }
                self.updateFilterButtonTitle(with: filtersSubject)
                self.updatePredicate(searchTerm: searchTerm, filters: filtersSubject)
                self.reloadData()
                self.syncingCoordinator.resynchronize()
            }.store(in: &subscriptions)
    }

    func updateFilterButtonTitle(with filters: FilterProductListViewModel.Filters) {
        let activeFiltersCount = filters.numberOfActiveFilters
        if activeFiltersCount == 0 {
            filterButtonTitle = Localization.filterButtonWithoutActiveFilters
        } else {
            filterButtonTitle = String.localizedStringWithFormat(Localization.filterButtonWithActiveFilters, activeFiltersCount)
        }
    }
}

// MARK: - Multiple selection support
private extension ProductSelectorViewModel {
    /// Toggles the selection of the specified product.
    ///
    func toggleSelection(productID: Int64) {
        if initialSelectedItems.contains(productID) {
            initialSelectedItems.removeAll(where: { $0 == productID })
        }

        if selectedProductIDs.contains(productID) {
            selectedProductIDs.removeAll(where: { $0 == productID })
        } else {
            selectedProductIDs.append(productID)
        }
    }

    /// Update selected product and variation IDs from initial selected items
    ///
    func updateSelectionsFromInitialSelectedItems() {
        guard initialSelectedItems.isNotEmpty else {
            return
        }
        for id in initialSelectedItems {
            guard !selectedProductIDs.contains(id) && !selectedProductVariationIDs.contains(id) else {
                continue
            }
            if products.contains(where: { $0.productID == id }) {
                selectedProductIDs.append(id)
            } else {
                selectedProductVariationIDs.append(id)
            }
        }
    }

    /// Observes changes in selections to update product rows
    ///
    func observeSelections() {
        $sections.combineLatest($selectedProductIDs, $selectedProductVariationIDs) {
            [weak self] sections, selectedProductIDs, selectedVariationIDs -> [ProductsSectionViewModel] in
            guard let self = self else {
                return []
            }
            return self.generateProductsSectionViewModels(sections: sections,
                                            selectedProductIDs: selectedProductIDs,
                                            selectedProductVariationIDs: selectedVariationIDs)
        }.assign(to: &$productsSectionViewModels)
    }

    func generateProductsSectionViewModels(sections: [ProductSelectorSection],
                                           selectedProductIDs: [Int64],
                                           selectedProductVariationIDs: [Int64]) -> [ProductsSectionViewModel] {
        sections.map { ProductsSectionViewModel(title: $0.type.title,
                                                productRows: generateProductRows(products: $0.products,
                                                                                 selectedProductIDs: selectedProductIDs,
                                                                                 selectedProductVariationIDs: selectedProductVariationIDs)) }
    }

    /// Generates product rows based on products and selected product/variation IDs
    ///
    func generateProductRows(products: [Product], selectedProductIDs: [Int64], selectedProductVariationIDs: [Int64]) -> [ProductRowViewModel] {
        return products.map { product in
            var selectedState: ProductRow.SelectedState
            if product.variations.isEmpty {
                selectedState = selectedProductIDs.contains(product.productID) ? .selected : .notSelected
            } else {
                let intersection = Set(product.variations).intersection(Set(selectedProductVariationIDs))
                if intersection.isEmpty {
                    selectedState = .notSelected
                } else if intersection.count == product.variations.count {
                    selectedState = .selected
                } else {
                    selectedState = .partiallySelected
                }
            }
            return ProductRowViewModel(product: product, canChangeQuantity: false, selectedState: selectedState)
        }
    }
}

// MARK: - Utils
extension ProductSelectorViewModel {
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

    /// Add Product to Order notices
    ///
    enum NoticeFactory {
        /// Returns a product sync error notice with a retry button.
        ///
        static func productSyncNotice(retryAction: @escaping () -> Void) -> Notice {
            Notice(title: Localization.syncErrorMessage, feedbackType: .error, actionTitle: Localization.errorActionTitle) {
                retryAction()
            }
        }

        /// Returns a product search error notice with a retry button.
        ///
        static func productSearchNotice(retryAction: @escaping () -> Void) -> Notice {
            Notice(title: Localization.searchErrorMessage, feedbackType: .error, actionTitle: Localization.errorActionTitle) {
                retryAction()
            }
        }
    }
}

private extension ProductSelectorViewModel {
    enum Localization {
        static let syncErrorMessage = NSLocalizedString("There was an error syncing products",
                                                        comment: "Notice displayed when syncing the list of products fails")
        static let searchErrorMessage = NSLocalizedString("There was an error searching products",
                                                          comment: "Notice displayed when searching the list of products fails")
        static let errorActionTitle = NSLocalizedString("Retry", comment: "Retry action for an error notice")
        static let filterButtonWithoutActiveFilters = NSLocalizedString(
            "Filter",
            comment: "Title of the button to select all products on the Select Product screen"
        )
        static let filterButtonWithActiveFilters = NSLocalizedString(
                "Filter (%ld)",
                comment: "Title of the button to filter products with filters applied on the Select Product screen"
        )
        static let popularProductsSectionTitle = NSLocalizedString("Popular", comment: "Section title for popular products on the Select Product screen.")
        static let lastSoldProductsSectionTitle = NSLocalizedString("Last Sold", comment: "Section title for last sold products on the Select Product screen.")
        static let productsSectionTitle = NSLocalizedString("Products", comment: "Section title for products on the Select Product screen.")
    }
}

private extension ProductSelectorViewModel {
    enum Constants {
        static let topSectionsMaxLength = 5
    }
}
