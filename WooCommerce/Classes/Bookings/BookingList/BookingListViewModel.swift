// periphery:ignore:all
import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `BookingListView`
final class BookingListViewModel: ObservableObject {

    @Published private(set) var bookings: [Booking] = []

    private let siteID: Int64
    private let stores: StoresManager
    private let storage: StorageManagerType

    /// Keeps track of the current state of the syncing
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Booking ResultsController.
    private lazy var resultsController: ResultsController<StorageBooking> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByDate = NSSortDescriptor(key: "dateCreated", ascending: false)
        let resultsController = ResultsController<StorageBooking>(storageManager: storage,
                                                                  matching: predicate,
                                                                  sortedBy: [sortDescriptorByDate])
        return resultsController
    }()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.stores = stores
        self.storage = storage
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

        configureResultsController()
        configurePaginationTracker()
    }

    /// Called when loading the first page of bookings.
    func loadBookings() {
        paginationTracker.syncFirstPage()
    }

    /// Called when the next page should be loaded.
    func onLoadNextPageAction() {
        paginationTracker.ensureNextPageIsSynced()
    }

    /// Called when the user pulls down the list to refresh.
    /// - Parameter completion: called when the refresh completes.
    func onRefreshAction(completion: @escaping () -> Void) {
        paginationTracker.resync(reason: nil) {
            completion()
        }
    }
}

// MARK: Configuration

private extension BookingListViewModel {
    func configurePaginationTracker() {
        paginationTracker.delegate = self
    }

    /// Performs initial fetch from storage and updates results.
    func configureResultsController() {
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
    func updateResults() {
        bookings = resultsController.fetchedObjects
        transitionToResultsUpdatedState()
    }
}

extension BookingListViewModel: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState()
        let action = BookingAction.synchronizeBookings(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            switch result {
            case .success(let hasNextPage):
                onCompletion?(.success(hasNextPage))

            case .failure(let error):
                DDLogError("⛔️ Error synchronizing bookings: \(error)")
                onCompletion?(.failure(error))
            }

            self?.updateResults()
        }
        stores.dispatch(action)
    }
}

// MARK: State Machine

extension BookingListViewModel {
    /// Represents possible states for syncing bookings.
    enum SyncState: Equatable {
        case syncingFirstPage
        case results
        case empty
    }

    /// Update states for sync from remote.
    func transitionToSyncingState() {
        shouldShowBottomActivityIndicator = true
        if bookings.isEmpty {
            syncState = .syncingFirstPage
        }
    }

    /// Update states after sync is complete.
    func transitionToResultsUpdatedState() {
        shouldShowBottomActivityIndicator = false
        syncState = bookings.isNotEmpty ? .results : .empty
    }
}
