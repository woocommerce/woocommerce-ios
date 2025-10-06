import Foundation
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `BookingListView`
final class BookingListViewModel: ObservableObject {

    @Published private(set) var bookings: [Booking] = []

    @Published var errorFetching = false

    var hasFilters: Bool {
        // TODO: Update when adding filters
        return false
    }

    var emptyStateTitle: String {
        type.emptyStateTitle(hasFilters: hasFilters)
    }

    var emptyStateDescription: String {
        type.emptyStateDescription(hasFilters: hasFilters)
    }

    private let siteID: Int64
    private let type: BookingListTab
    private let stores: StoresManager
    private let storage: StorageManagerType
    private let currentDate: Date

    private static let refreshCacheReason = "refresh-cache"

    /// Keeps track of the current state of the syncing
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Booking ResultsController.
    private lazy var resultsController: ResultsController<StorageBooking> = {
        var predicates = [NSPredicate(format: "siteID == %lld", siteID)]
        if let before = type.startDateBefore(currentDate: currentDate) {
            predicates.append(NSPredicate(format: "startDate < %@", before as NSDate))
        }
        if let after = type.startDateAfter(currentDate: currentDate) {
            predicates.append(NSPredicate(format: "startDate > %@", after as NSDate))
        }
        let combinedPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        let sortDescriptorByDate = NSSortDescriptor(key: "startDate", ascending: false)
        let resultsController = ResultsController<StorageBooking>(storageManager: storage,
                                                                  matching: combinedPredicate,
                                                                  sortedBy: [sortDescriptorByDate])
        return resultsController
    }()

    init(siteID: Int64,
         type: BookingListTab,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         currentDate: Date = Date()) {
        self.siteID = siteID
        self.type = type
        self.stores = stores
        self.storage = storage
        self.currentDate = currentDate
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
    @MainActor
    func onRefreshAction() async {
        await withCheckedContinuation { continuation in
            paginationTracker.resync(reason: Self.refreshCacheReason) {
                continuation.resume(returning: ())
            }
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
        withAnimation {
            errorFetching = false
        }
        let shouldClearCache = reason == Self.refreshCacheReason
        let action = BookingAction.synchronizeBookings(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            startDateBefore: type.startDateBefore(currentDate: currentDate)?.ISO8601Format(),
            startDateAfter: type.startDateAfter(currentDate: currentDate)?.ISO8601Format(),
            shouldClearCache: shouldClearCache
        ) { [weak self] result in
            switch result {
            case .success(let hasNextPage):
                onCompletion?(.success(hasNextPage))

            case .failure(let error):
                DDLogError("⛔️ Error synchronizing bookings: \(error)")
                withAnimation {
                    self?.errorFetching = true
                }
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
