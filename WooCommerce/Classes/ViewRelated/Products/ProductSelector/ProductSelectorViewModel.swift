import Yosemite
import protocol Experiments.FeatureFlagService
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

/// How to handle a product selection depending on its type.
///
enum SelectionHandling {
    // Treat all products as a single item, and select it right away.
    case simple
    // Handle product selection depending on the product type. For example, selecting a variation product might open
    // the variation product selector.
    case normal
}

/// The amount of products that can be selected in the product selector.
///
enum SelectionMode {
    // Allow selecting only a single product
    case single
    // Support selecting multiple products
    case multiple
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

    private let featureFlagService: FeatureFlagService

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

    /// Supports infinite scroll: keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    private let paginationTracker: PaginationTracker

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

    @Published var productSearchFilter: ProductSearchFilter = .all

    /// All selected product and variations ids.
    ///
    @Published private var selectedItemsIDs: [Int64] = []

    var totalSelectedItemsCount: Int {
        selectedItemsIDs.count
    }

    /// Whether the product list should contains only purchasable items.
    ///
    private let purchasableItemsOnly: Bool

    private let shouldDeleteStoredProductsOnFirstPage: Bool

    /// Closure to be invoked when "Clear Selection" is called.
    ///
    private let onAllSelectionsCleared: (() -> Void)?

    /// Closure to be invoked when variations "Clear Selection" is called.
    ///
    private let onSelectedVariationsCleared: (() -> Void)?

    private let onCloseButtonTapped: (() -> Void)?

    private let onConfigureProductRow: ((_ product: Product) -> Void)?

    /// How product selector should handle product selection.
    ///
    let selectionHandlingMode: SelectionHandling

    /// Whether merchants can select single or multiple product.
    ///
    let selectionMode: SelectionMode

    init(siteID: Int64,
         selectedItemIDs: [Int64] = [],
         purchasableItemsOnly: Bool = false,
         selectionHandlingMode: SelectionHandling = .normal,
         selectionMode: SelectionMode = .multiple,
         shouldDeleteStoredProductsOnFirstPage: Bool = true,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         toggleAllVariationsOnSelection: Bool = true,
         topProductsProvider: ProductSelectorTopProductsProviderProtocol? = nil,
         pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex,
         pageSize: Int = PaginationTracker.Defaults.pageSize,
         onProductSelectionStateChanged: ((Product) -> Void)? = nil,
         onVariationSelectionStateChanged: ((ProductVariation, Product) -> Void)? = nil,
         onMultipleSelectionCompleted: (([Int64]) -> Void)? = nil,
         onAllSelectionsCleared: (() -> Void)? = nil,
         onSelectedVariationsCleared: (() -> Void)? = nil,
         onCloseButtonTapped: (() -> Void)? = nil,
         onConfigureProductRow: ((_ product: Product) -> Void)? = nil) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.toggleAllVariationsOnSelection = toggleAllVariationsOnSelection
        self.onProductSelectionStateChanged = onProductSelectionStateChanged
        self.onVariationSelectionStateChanged = onVariationSelectionStateChanged
        self.onMultipleSelectionCompleted = onMultipleSelectionCompleted
        self.selectedItemsIDs = selectedItemIDs
        self.purchasableItemsOnly = purchasableItemsOnly
        self.selectionHandlingMode = selectionHandlingMode
        self.selectionMode = selectionMode
        self.shouldDeleteStoredProductsOnFirstPage = shouldDeleteStoredProductsOnFirstPage
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex, pageSize: pageSize)
        self.onAllSelectionsCleared = onAllSelectionsCleared
        self.onSelectedVariationsCleared = onSelectedVariationsCleared
        self.onCloseButtonTapped = onCloseButtonTapped
        self.onConfigureProductRow = onConfigureProductRow
        tracker = ProductSelectorViewModelTracker(analytics: analytics, trackProductsSource: topProductsProvider != nil)

        topProductsFromCachedOrders = topProductsProvider?.provideTopProducts(siteID: siteID) ?? .empty
        tracker.viewModel = self

        configurePaginationTracker()
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
        toggleSelection(id: productID)

        // The SKU search gives product variations as products. Here we have to handle that.
        if let productVariation = selectedProduct.toProductVariation() {
            // We generate a parent product, which has the same info with the right ID, that is, the product variation parent id.
            onVariationSelectionStateChanged?(productVariation, selectedProduct.copy(productID: selectedProduct.parentID))
        } else {
            onProductSelectionStateChanged?(selectedProduct)
        }
    }

    /// Adds a product or variation ID to the product selector from an external source (e.g. bundle configuration form for bundle products).
    /// - Parameter id: Product or variation ID to add to the product selector.
    func addSelection(id: Int64) {
        selectedItemsIDs.append(id)
    }

    private func toggleSelection(id: Int64) {
        // In single selection mode, remove previously selected product first.
        if selectionMode == .single {
            clearSelection()
        }

        if selectedItemsIDs.contains(id) {
            selectedItemsIDs = selectedItemsIDs.filter { $0 != id }
        } else {
            selectedItemsIDs.append(id)
        }
    }

    /// Get the view model for a list of product variations to add to the order
    ///
    func getVariationsViewModel(for productID: Int64) -> ProductVariationSelectorViewModel? {
        guard let variableProduct = products.first(where: { $0.productID == productID }), variableProduct.variations.isNotEmpty else {
            return nil
        }
        let selectedItems = selectedItemsIDs.filter { variableProduct.variations.contains($0) }
        return ProductVariationSelectorViewModel(siteID: siteID,
                                                 product: variableProduct,
                                                 selectedProductVariationIDs: selectedItems,
                                                 purchasableItemsOnly: purchasableItemsOnly,
                                                 selectionMode: selectionMode,
                                                 onVariationSelectionStateChanged: onVariationSelectionStateChanged,
                                                 onSelectionsCleared: onSelectedVariationsCleared)
    }

    /// Clears the current search term and filters to display the full product list.
    ///
    func clearSearchAndFilters() {
        searchTerm = ""
        productSearchFilter = .all
        filtersSubject.send(.init())
    }

    /// Updates selected variation list based on the new selected IDs
    ///
    func updateSelectedVariations(productID: Int64, selectedVariationIDs: [Int64]) {
        // In single SelectionMode, merchants can first select a simple product,
        // then enter a variable product and select a variation. In this situation,
        // we have to remove the selected simple product first.
        if selectedVariationIDs.count > 0 && selectionMode == .single {
            clearSelection()
        }

        guard let variableProduct = products.first(where: { $0.productID == productID }),
              variableProduct.variations.isNotEmpty else {
            return
        }

        // remove all previous selected variations
        selectedItemsIDs.removeAll(where: { variableProduct.variations.contains($0) })
        // append new selected IDs
        selectedItemsIDs.append(contentsOf: selectedVariationIDs)

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
        let intersection = Set(variableProduct.variations).intersection(Set(selectedItemsIDs))
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
        tracker.trackConfirmButtonTapped(with: selectedItemsIDs.count)
        onMultipleSelectionCompleted?(selectedItemsIDs)
    }

    /// Triggers completion closure when the close button is tapped
    ///
    func closeButtonTapped() {
        onCloseButtonTapped?()
    }

    /// Unselect all items.
    ///
    func clearSelection() {
        selectedItemsIDs = []

        onAllSelectionsCleared?()
    }
}

// MARK: - PaginationTrackerDelegate conformance
extension ProductSelectorViewModel: PaginationTrackerDelegate {
    /// Sync products from remote.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: SyncCompletion?) {
        transitionToSyncingState(pageNumber: pageNumber)

        if searchTerm.isNotEmpty {
            searchProducts(siteID: siteID, keyword: searchTerm, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        } else {
            syncProducts(pageNumber: pageNumber, pageSize: pageSize, reason: reason, onCompletion: onCompletion)
        }
    }

    /// Sync all products from remote.
    ///
    private func syncProducts(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: SyncCompletion?) {
        let action = ProductAction.synchronizeProducts(siteID: siteID,
                                                       pageNumber: pageNumber,
                                                       pageSize: pageSize,
                                                       stockStatus: filtersSubject.value.stockStatus,
                                                       productStatus: filtersSubject.value.productStatus,
                                                       productType: filtersSubject.value.promotableProductType?.productType,
                                                       productCategory: filtersSubject.value.productCategory,
                                                       sortOrder: .nameAscending,
                                                       shouldDeleteStoredProductsOnFirstPage: shouldDeleteStoredProductsOnFirstPage) { [weak self] result in
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
            onCompletion?(result)
        }
        stores.dispatch(action)
    }

    /// Sync products matching a given keyword.
    ///
    private func searchProducts(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: SyncCompletion?) {
        searchProductsInCacheIfPossible(siteID: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize)

        let action = ProductAction.searchProducts(siteID: siteID,
                                                  keyword: keyword,
                                                  filter: productSearchFilter,
                                                  pageNumber: pageNumber,
                                                  pageSize: pageSize,
                                                  stockStatus: filtersSubject.value.stockStatus,
                                                  productStatus: filtersSubject.value.productStatus,
                                                  productType: filtersSubject.value.promotableProductType?.productType,
                                                  productCategory: filtersSubject.value.productCategory) { [weak self] result in
            // Don't continue if this isn't the latest search.
            guard let self = self, keyword == self.searchTerm else {
                return
            }

            switch result {
            case .success:
                self.tracker.trackSearchSuccessIfNecessary()
                self.reloadData()
            case .failure(let error):
                self.tracker.trackSearchFailureIfNecessary(with: error)
                self.notice = NoticeFactory.productSearchNotice() { [weak self] in
                    self?.searchProducts(siteID: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize, onCompletion: nil)
                }
                DDLogError("⛔️ Error searching products during order creation: \(error)")
            }

            self.transitionToResultsUpdatedState()
            onCompletion?(result)
        }

        stores.dispatch(action)
        tracker.trackSearchTriggered()
    }

    private func searchProductsInCacheIfPossible(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int) {
        // At the moment local search supports neither filters nor pagination
        guard filtersSubject.value.numberOfActiveFilters == 0,
              pageNumber == 1,
              productSearchFilter == .all else {
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
        paginationTracker.syncFirstPage()
    }

    /// Sync next page of products from remote.
    ///
    func syncNextPage() {
        paginationTracker.ensureNextPageIsSynced()
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
    func transitionToSyncingState(pageNumber: Int) {
        shouldShowScrollIndicator = true
        notice = nil

        if shouldShowLoadingScreen(pageNumber: pageNumber) {
            syncStatus = .loading
        }
    }

    func shouldShowLoadingScreen(pageNumber: Int) -> Bool {
        guard pageNumber == 1 else {
            return false
        }

        guard searchTerm.isEmpty &&
              filtersSubject.value.numberOfActiveFilters == 0 else {
            return true
        }


        return products.isEmpty
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

    func updatePredicate(searchTerm: String, filters: FilterProductListViewModel.Filters, productSearchFilter: ProductSearchFilter) {
        productsResultsController.updatePredicate(siteID: siteID,
                                                  stockStatus: filters.stockStatus,
                                                  productStatus: filters.productStatus,
                                                  productType: filters.promotableProductType?.productType)
        if searchTerm.isNotEmpty {
            // When the search query changes, also includes the original results predicate in addition to the search keyword and filter key.
            let searchResultsPredicate = NSPredicate(format: "SUBQUERY(searchResults, $result, $result.keyword = %@ AND $result.filterKey = %@).@count > 0",
                                                     searchTerm, productSearchFilter.rawValue)
            let subpredicates = [resultsPredicate, searchResultsPredicate].compactMap { $0 }
            productsResultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        } else {
            // Resets the results to the full product list when there is no search query.
            productsResultsController.predicate = resultsPredicate
        }
    }

    /// Setup: Pagination Tracker
    ///
    func configurePaginationTracker() {
        paginationTracker.delegate = self
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
        let searchFilterPublisher = $productSearchFilter
            .removeDuplicates()
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)

        Publishers.CombineLatest3(searchTermPublisher, filtersPublisher, searchFilterPublisher)
            .sink { [weak self] searchTerm, filtersSubject, productSearchFilter in
                guard let self = self else { return }
                self.updateFilterButtonTitle(with: filtersSubject)
                self.updatePredicate(searchTerm: searchTerm, filters: filtersSubject, productSearchFilter: productSearchFilter)
                self.reloadData()
                self.paginationTracker.resync()
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
    /// Observes changes in selections to update product rows
    ///
    func observeSelections() {
        $sections.combineLatest($selectedItemsIDs) {
            [weak self] sections, selectedItemsIDs -> [ProductsSectionViewModel] in
            guard let self = self else {
                return []
            }
            return self.generateProductsSectionViewModels(sections: sections,
                                                          selectedItemsIDs: selectedItemsIDs)
        }.assign(to: &$productsSectionViewModels)
    }

    func generateProductsSectionViewModels(sections: [ProductSelectorSection],
                                           selectedItemsIDs: [Int64]) -> [ProductsSectionViewModel] {
        sections.map { ProductsSectionViewModel(title: $0.type.title,
                                                productRows: generateProductRows(products: $0.products,
                                                                                 selectedItemsIDs: selectedItemsIDs)) }
    }

    /// Generates product rows based on products and selected product/variation IDs
    ///
    func generateProductRows(products: [Product], selectedItemsIDs: [Int64]) -> [ProductRowViewModel] {
        return products.map { product in
            var selectedState: ProductRow.SelectedState

            // Toggle selected state right away if:
            // - not a variation product, or
            // - a variation product in simple selection handling mode.
            if product.variations.isEmpty || selectionHandlingMode == .simple {
                selectedState = selectedItemsIDs.contains(product.productID) ? .selected : .notSelected
            } else {
                let intersection = Set(product.variations).intersection(Set(selectedItemsIDs))
                if intersection.isEmpty {
                    selectedState = .notSelected
                } else if intersection.count == product.variations.count {
                    selectedState = .selected
                } else {
                    selectedState = .partiallySelected
                }
            }

            let configure: (() -> Void)? = onConfigureProductRow == nil ? nil: { [weak self] in
                self?.onConfigureProductRow?(product)
            }
            return ProductRowViewModel(product: product,
                                       selectedState: selectedState,
                                       featureFlagService: featureFlagService,
                                       configure: configure)
        }
    }
}

// MARK: - Utils
extension ProductSelectorViewModel {
    /// Represents possible statuses for syncing products
    ///
    enum SyncStatus {
        case loading
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
                            imageURL: nil,
                            isConfigurable: false)
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
