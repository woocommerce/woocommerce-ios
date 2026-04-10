import Foundation
import Combine
import Yosemite
import protocol Storage.StorageManagerType

// Generic view model for syncable data list selector views
final class SyncableListSelectorViewModel<Syncable: ListSyncable>: ObservableObject {
    @Published private(set) var items: [Syncable.ModelType] = []

    /// Keeps track of the current state of the syncing
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    @Published var searchQuery: String = ""

    private let syncable: Syncable
    private let stores: StoresManager
    private let storage: StorageManagerType

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Stores the current search keyword for pagination
    private var currentSearchKeyword: String = ""

    /// Cancellable for search query observation
    private var searchCancellable: AnyCancellable?

    /// ResultsController configured by the syncable
    private lazy var resultsController: ResultsController<Syncable.StorageType> = {
        let predicate = syncable.createPredicate()
        let sortDescriptors = syncable.createSortDescriptors()
        return ResultsController<Syncable.StorageType>(
            storageManager: storage,
            matching: predicate,
            sortedBy: sortDescriptors
        )
    }()

    init(syncable: Syncable,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager) {
        self.syncable = syncable
        self.stores = stores
        self.storage = storage
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

        configureResultsController()
        configurePaginationTracker()
        configureSearchObserver()
    }

    /// Called when loading the first page of resources.
    func loadResources() {
        paginationTracker.syncFirstPage()
    }

    /// Called when the next page should be loaded.
    func onLoadNextPageAction() {
        paginationTracker.ensureNextPageIsSynced()
    }

    // MARK: - Private helper methods

    private func configurePaginationTracker() {
        paginationTracker.delegate = self
    }

    /// Observes search query changes and triggers search with debouncing
    private func configureSearchObserver() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] newQuery in
                self?.handleSearchQueryChange(newQuery)
            }
    }

    /// Handles search query changes by resetting pagination and triggering new search
    private func handleSearchQueryChange(_ query: String) {
        currentSearchKeyword = query

        // Update the predicate to filter by search results if needed
        var predicates = [syncable.createPredicate()]
        if !query.isEmpty, let searchPredicate = syncable.createSearchPredicate(keyword: query) {
            predicates.append(searchPredicate)
        }
        resultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        paginationTracker.syncFirstPage()
    }

    /// Performs initial fetch from storage and updates results.
    private func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateResults()
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.updateResults()
        }
        do {
            try resultsController.performFetch()
            updateResults()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Updates row view models and sync state.
    private func updateResults() {
        items = resultsController.fetchedObjects
        transitionToResultsUpdatedState()
    }
}

extension SyncableListSelectorViewModel: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState()

        // Use search action if there's a search keyword, otherwise use regular sync action
        let action: Action
        if currentSearchKeyword.isEmpty {
            action = syncable.createSyncAction(
                pageNumber: pageNumber,
                pageSize: pageSize
            ) { [weak self] result in
                self?.handleSyncResult(result, onCompletion: onCompletion)
            }
        } else {
            action = syncable.createSearchAction(
                keyword: currentSearchKeyword,
                pageNumber: pageNumber,
                pageSize: pageSize
            ) { [weak self] result in
                self?.handleSyncResult(result, onCompletion: onCompletion)
            }
        }

        stores.dispatch(action)
    }

    private func handleSyncResult(_ result: Result<Bool, Error>, onCompletion: SyncCompletion?) {
        switch result {
        case .success(let hasNextPage):
            onCompletion?(.success(hasNextPage))

        case .failure(let error):
            DDLogError("⛔️ Error synchronizing: \(error)")
            onCompletion?(.failure(error))
        }

        updateResults()
    }
}

// MARK: State Machine

extension SyncableListSelectorViewModel {
    /// Represents possible states for syncing items.
    enum SyncState: Equatable {
        case syncingFirstPage
        case results
        case empty
    }

    /// Update states for sync from remote.
    func transitionToSyncingState() {
        shouldShowBottomActivityIndicator = true
        if items.isEmpty {
            syncState = .syncingFirstPage
        }
    }

    /// Update states after sync is complete.
    func transitionToResultsUpdatedState() {
        shouldShowBottomActivityIndicator = false
        syncState = items.isNotEmpty ? .results : .empty
    }
}
