import Foundation
import Yosemite
import protocol Storage.StorageManagerType

// Generic view model for syncable data list selector views
final class SyncableListSelectorViewModel<Syncable: ListSyncable>: ObservableObject {
    @Published private(set) var items: [Syncable.ModelType] = []

    /// Keeps track of the current state of the syncing
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    private let syncable: Syncable
    private let stores: StoresManager
    private let storage: StorageManagerType

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

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
        let action = syncable.createSyncAction(
            pageNumber: pageNumber,
            pageSize: pageSize
        ) { [weak self] result in
            switch result {
            case .success(let hasNextPage):
                onCompletion?(.success(hasNextPage))

            case .failure(let error):
                DDLogError("⛔️ Error synchronizing: \(error)")
                onCompletion?(.failure(error))
            }

            self?.updateResults()
        }
        stores.dispatch(action)
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
