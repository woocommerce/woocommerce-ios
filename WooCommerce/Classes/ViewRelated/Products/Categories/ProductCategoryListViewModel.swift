import Combine
import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// Classes conforming to this protocol can enrich the Product Category List UI,
/// e.g by adding extra rows
///
protocol ProductCategoryListViewModelEnrichingDataSource: AnyObject {
    /// This method enriches the passed view models array so the case logic specific view models can be added
    ///
    func enrichCategoryViewModels(_ viewModels: [ProductCategoryCellViewModel]) -> [ProductCategoryCellViewModel]
}

/// Classes conforming to this protocol are notified of relevant events
///
protocol ProductCategoryListViewModelDelegate: AnyObject {
    /// Called when a row is selected
    ///
    func viewModel(_ viewModel: ProductCategoryListViewModel, didSelectRowAt index: Int)
}

/// Manages the presentation of a `ProductCategoryListView`, taking care of fetching, syncing, and providing the category view models for each cell
///
final class ProductCategoryListViewModel {

    /// Obscure token that allows the view model to retry the synchronizeCategories operation
    ///
    struct RetryToken: Equatable {
        fileprivate let fromPageNumber: Int
    }

    /// Represents the current state of `synchronizeCategories` action. Useful for the consumer to update it's UI upon changes
    ///
    enum SyncingState: Equatable {
        case initialized
        case syncing
        case failed(RetryToken)
        case synced
    }

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let storesManager: StoresManager

    /// Storage to fetch categories from.
    ///
    private let storageManager: StorageManagerType

    /// Site Id of the related categories
    ///
    private let siteID: Int64

    /// Initially selected category IDs.
    /// This is mutable so that we can remove any item when unselecting it manually.
    ///
    private var initiallySelectedIDs: [Int64]

    /// Product categories that will be eventually modified by the user
    ///
    @Published private(set) var selectedCategories: [ProductCategory]

    /// Search query from the search bar
    /// 
    @Published var searchQuery: String = ""

    private var searchQuerySubscription: AnyCancellable?

    /// Array of view models to be rendered by the View Controller.
    ///
    @Published private(set) var categoryViewModels: [ProductCategoryCellViewModel] = []

    /// Closure invoked when the list needs to reload
    ///
    private var onReloadNeeded: (() -> Void)?

    /// Delegate to be notified of meaningful events
    ///
    private weak var delegate: ProductCategoryListViewModelDelegate?

    /// Enriches product category cells view models
    ///
    private weak var enrichingDataSource: ProductCategoryListViewModelEnrichingDataSource?

    /// Callback when a product category is selected. Passing nil means all categories are deselected
    ///
    typealias ProductCategorySelection = (ProductCategory?) -> Void
    private var onProductCategorySelection: ProductCategorySelection?

    /// Current  category synchronization state
    ///
    @Published private(set) var syncCategoriesState: SyncingState = .initialized

    private lazy var resultController: ResultsController<StorageProductCategory> = {
        let predicate = NSPredicate(format: "siteID = %lld", self.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductCategory.name, ascending: true)
        return ResultsController<StorageProductCategory>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    init(siteID: Int64,
         selectedCategoryIDs: [Int64] = [],
         selectedCategories: [ProductCategory] = [],
         storesManager: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         enrichingDataSource: ProductCategoryListViewModelEnrichingDataSource? = nil,
         delegate: ProductCategoryListViewModelDelegate? = nil,
         onProductCategorySelection: ProductCategorySelection? = nil) {
        self.storesManager = storesManager
        self.storageManager = storageManager
        self.siteID = siteID
        self.selectedCategories = selectedCategories
        self.enrichingDataSource = enrichingDataSource
        self.delegate = delegate
        self.onProductCategorySelection = onProductCategorySelection
        self.initiallySelectedIDs = selectedCategoryIDs

        try? resultController.performFetch()
        updateViewModelsArray()
        configureProductSearch()
    }

    /// Load existing categories from storage and fire the synchronize all categories action.
    ///
    func performFetch() {
        synchronizeAllCategories()
    }

    /// Retry product categories synchronization when `syncCategoriesState` is on a `.failed` state.
    ///
    func retryCategorySynchronization(retryToken: RetryToken) {
        guard syncCategoriesState == .failed(retryToken) else {
            return
        }
        synchronizeAllCategories(fromPageNumber: retryToken.fromPageNumber)
    }

    /// Observe the need of reload by passing a closure that will be invoked when there is a need to reload the data.
    /// Calling this method will remove any other previous observer.
    ///
    func observeReloadNeeded(onReloadNeeded: @escaping () -> Void) {
        self.onReloadNeeded = onReloadNeeded
    }

    /// The invokation of this method will trigger a reload of the list without performing any new fetch,
    /// neither local or remote.
    ///
    func reloadData() {
        onReloadNeeded?()
    }

    /// Add a new category added remotely, that will be selected
    ///
    func addAndSelectNewCategory(category: ProductCategory) {
        selectedCategories.append(category)
        updateViewModelsArray()
        onProductCategorySelection?(category)
        reloadData()
    }

    /// Resets the selected categories. This method does not trigger any UI reload
    ///
    func resetSelectedCategories() {
        selectedCategories = []
    }

    /// Resets the selected categories and triggers UI reload
    ///
    func resetSelectedCategoriesAndReload() {
        initiallySelectedIDs = []
        resetSelectedCategories()
        updateViewModelsArray()
        reloadData()
    }

    /// Select or Deselect a category, notifying the delegate before any other action
    ///
    func selectOrDeselectCategory(index: Int) {
        delegate?.viewModel(self, didSelectRowAt: index)

        guard let categoryViewModel = categoryViewModels[safe: index] else {
            return
        }

        // If the category selected exist, remove it, otherwise, add it to `selectedCategories`.
        if let indexCategory = selectedCategories.firstIndex(where: { $0.categoryID == categoryViewModel.categoryID}) {
            let discardedItem = selectedCategories.remove(at: indexCategory)
            initiallySelectedIDs.removeAll(where: { $0 == discardedItem.categoryID })
        } else {
            let selectedCategory = resultController.fetchedObjects.first(where: { $0.categoryID == categoryViewModel.categoryID })

            if let selectedCategory = selectedCategory {
                selectedCategories.append(selectedCategory)
            }

            onProductCategorySelection?(selectedCategory)
        }

        updateViewModelsArray()
    }

    /// Updates  `categoryViewModels` from  the resultController's fetched objects,
    /// letting the enriching data source enrich the view models array if necessary.
    ///
    func updateViewModelsArray() {
        let fetchedCategories = resultController.fetchedObjects
        updateInitialItemsIfNeeded(with: fetchedCategories)
        let baseViewModels: [ProductCategoryCellViewModel]
        if searchQuery.isNotEmpty {
            baseViewModels = ProductCategoryListViewModel.CellViewModelBuilder.flatViewModels(from: fetchedCategories, selectedCategories: selectedCategories)
        } else {
            baseViewModels = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(from: fetchedCategories, selectedCategories: selectedCategories)
        }

        categoryViewModels = enrichingDataSource?.enrichCategoryViewModels(baseViewModels) ?? baseViewModels
    }

    /// Update `selectedCategories` based on initially selected items.
    ///
    private func updateInitialItemsIfNeeded(with categories: [ProductCategory]) {
        guard initiallySelectedIDs.isNotEmpty && selectedCategories.isEmpty else {
            return
        }
        selectedCategories = initiallySelectedIDs.compactMap { id in
            categories.first(where: { $0.categoryID == id })
        }
    }

    /// Updates the category results predicate & reload the list
    ///
    private func configureProductSearch() {
        searchQuerySubscription = $searchQuery
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] newQuery in
                guard let self = self else { return }

                if newQuery.isNotEmpty {
                    let searchPredicate = NSPredicate(format: "siteID = %lld AND ((name CONTAINS[cd] %@) OR (slug CONTAINS[cd] %@))",
                                                      self.siteID,
                                                      newQuery.trimmingCharacters(in: .whitespacesAndNewlines),
                                                      newQuery.trimmingCharacters(in: .whitespacesAndNewlines))
                    self.resultController.predicate = searchPredicate
                } else {
                    // Resets the results to the full product list when there is no search query.
                    self.resultController.predicate = NSPredicate(format: "siteID = %lld", self.siteID)
                }
                try? self.resultController.performFetch()
                self.updateViewModelsArray()
                self.reloadData()
            }
    }
}

// MARK: - Synchronize Categories
//
private extension ProductCategoryListViewModel {
    /// Synchronizes all product categories starting at a specific page number. Default initial page number is set on `Default.firstPageNumber`
    ///
    func synchronizeAllCategories(fromPageNumber: Int = Default.firstPageNumber) {
        self.syncCategoriesState = .syncing
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: siteID, fromPageNumber: fromPageNumber) { [weak self] error in
            // Make sure we always have view models to display
            self?.updateViewModelsArray()

            if let error = error {
                ServiceLocator.analytics.track(.productCategoryListLoadFailed, withError: error)
                self?.handleSychronizeAllCategoriesError(error)
            } else {
                ServiceLocator.analytics.track(.productCategoryListLoaded)
                self?.syncCategoriesState = .synced
            }
        }
        storesManager.dispatch(action)
    }

    /// Update `syncCategoriesState` with the proper retryToken
    ///
    func handleSychronizeAllCategoriesError(_ error: ProductCategoryActionError) {
        switch error {
        case let .categoriesSynchronization(pageNumber, rawError):
            let retryToken = RetryToken(fromPageNumber: pageNumber)
            syncCategoriesState = .failed(retryToken)
            DDLogError("⛔️ Error fetching product categories: \(rawError.localizedDescription)")
        default:
            break
        }
    }
}

// MARK: - Constants
//
private extension ProductCategoryListViewModel {
    enum Default {
        public static let firstPageNumber = 1
    }
}
