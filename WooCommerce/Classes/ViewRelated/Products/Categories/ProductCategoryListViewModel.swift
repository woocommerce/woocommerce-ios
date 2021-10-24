import Foundation
import Yosemite

/// Classes conforming to this protocol can enrich the UI to be displayed
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

    /// Site Id of the related categories
    ///
    private let siteID: Int64

    /// Product categories that will be eventually modified by the user
    ///
    private(set) var selectedCategories: [ProductCategory]

    /// Array of view models to be rendered by the View Controller.
    ///
    private(set) var categoryViewModels: [ProductCategoryCellViewModel] = []

    /// Closure to be invoked when `synchronizeCategories` state  changes
    ///
    private var onSyncStateChange: ((SyncingState) -> Void)?

    /// Closure invoked when the list needs to reload
    ///
    private var onReloadNeeded: (() -> Void)?

    /// Delegate to be notified of meaningful events
    ///
    private weak var delegate: ProductCategoryListViewModelDelegate?

    /// Enriches product category cells view models
    ///
    private weak var dataSource: ProductCategoryListViewModelEnrichingDataSource?

    /// Current  category synchronization state
    ///
    private var syncCategoriesState: SyncingState = .initialized {
        didSet {
            guard syncCategoriesState != oldValue else {
                return
            }
            onSyncStateChange?(syncCategoriesState)
        }
    }

    private lazy var resultController: ResultsController<StorageProductCategory> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID = %ld", self.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductCategory.name, ascending: true)
        return ResultsController<StorageProductCategory>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    init(storesManager: StoresManager = ServiceLocator.stores,
         siteID: Int64,
         selectedCategories: [ProductCategory] = [],
         dataSource: ProductCategoryListViewModelEnrichingDataSource? = nil,
         delegate: ProductCategoryListViewModelDelegate? = nil) {
        self.storesManager = storesManager
        self.siteID = siteID
        self.selectedCategories = selectedCategories
        self.dataSource = dataSource
        self.delegate = delegate
    }

    /// Load existing categories from storage and fire the synchronize all categories action.
    ///
    func performFetch() {
        synchronizeAllCategories()
        try? resultController.performFetch()
    }

    /// Retry product categories synchronization when `syncCategoriesState` is on a `.failed` state.
    ///
    func retryCategorySynchronization(retryToken: RetryToken) {
        guard syncCategoriesState == .failed(retryToken) else {
            return
        }
        synchronizeAllCategories(fromPageNumber: retryToken.fromPageNumber)
    }

    /// Observes and notifies of changes made to product categories. the current state will be dispatched upon subscription.
    /// Calling this method will remove any other previous observer.
    ///
    func observeCategoryListStateChanges(onStateChanges: @escaping (SyncingState) -> Void) {
        onSyncStateChange = onStateChanges
        onSyncStateChange?(syncCategoriesState)
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
        reloadData()
    }

    /// Resets the selected categories. Please note that this method that not trigger any UI reload
    ///
    func resetSelectedCategories() {
        selectedCategories = []
    }

    /// Select or Deselect a category
    ///
    func selectOrDeselectCategory(index: Int) {
        delegate?.viewModel(self, didSelectRowAt: index)

        guard let categoryViewModel = categoryViewModels[safe: index] else {
            return
        }

        // If the category selected exist, remove it, otherwise, add it to `selectedCategories`.
        if let indexCategory = selectedCategories.firstIndex(where: { $0.categoryID == categoryViewModel.categoryID}) {
            selectedCategories.remove(at: indexCategory)
        }
        else if let category = resultController.fetchedObjects.first(where: { $0.categoryID == categoryViewModel.categoryID }) {
            selectedCategories.append(category)
        }

        updateViewModelsArray()
    }

    /// Updates  `categoryViewModels` from  the resultController's fetched objects.
    ///
    func updateViewModelsArray() {
        let fetchedCategories = resultController.fetchedObjects
        let baseViewModels = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(from: fetchedCategories, selectedCategories: selectedCategories)

        categoryViewModels = dataSource?.enrichCategoryViewModels( baseViewModels) ?? baseViewModels
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
