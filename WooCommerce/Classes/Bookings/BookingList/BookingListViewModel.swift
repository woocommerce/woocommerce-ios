import Foundation
import SwiftUI
import Yosemite
import Combine
import protocol Storage.StorageManagerType
import class Networking.BookingsRemote
import protocol WooFoundation.Analytics

protocol BookingListsRefreshCoordinating: AnyObject {
    func refreshAllLists() async
}

/// View model for `BookingListView`
final class BookingListViewModel: ObservableObject {

    @Published private(set) var bookings: [Booking] = []

    @Published var errorFetching = false

    @Published private(set) var hasFilters = false

    weak var refreshCoordinator: BookingListsRefreshCoordinating?

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
    private var currentOrder: SortBy = .newestToOldest

    private let tabDateFilters: BookingFilters
    private var filters: BookingFilters

    private static let refreshCacheReason = "refresh-cache"
    private static let reorderReason = "reorder"
    static let siblingRefreshReason = "sibling-refresh"

    /// Keeps track of the current state of the syncing
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Tracks if initial load has been triggered.
    private var hasLoadedInitially = false
    private let analytics: Analytics

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Booking ResultsController.
    private lazy var resultsController: ResultsController<StorageBooking> = {
        let sortDescriptorByDate = NSSortDescriptor(key: "startDate", ascending: false)
        let resultsController = ResultsController<StorageBooking>(storageManager: storage,
                                                                  matching: currentPredicate,
                                                                  sortedBy: [sortDescriptorByDate])
        return resultsController
    }()

    init(siteID: Int64,
         type: BookingListTab,
         parent: BookingListContainerViewModel? = nil,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         currentDate: Date = Date()) {
        self.siteID = siteID
        self.type = type
        self.stores = stores
        self.storage = storage
        self.analytics = analytics
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

        self.tabDateFilters = type.remoteFilters(currentDate: currentDate)
        self.filters = tabDateFilters

        configureResultsController()
        configurePaginationTracker()
    }

    /// Called when loading the first page of bookings.
    func loadBookings() {
        guard !hasLoadedInitially else { return }
        hasLoadedInitially = true
        paginationTracker.syncFirstPage()
    }

    /// Called when the next page should be loaded.
    func onLoadNextPageAction() {
        paginationTracker.ensureNextPageIsSynced()
    }

    /// Called when the user pulls down the list to refresh.
    func onRefreshAction() async {
        await refreshCoordinator?.refreshAllLists()
    }

    @MainActor
    func reloadData(reason: String = BookingListViewModel.refreshCacheReason) async {
        await withCheckedContinuation { continuation in
            paginationTracker.resync(reason: reason) {
                continuation.resume(returning: ())
            }
        }
    }

    /// Updates the sort order and reloads the results controller.
    func updateSortOrder(_ sortBy: SortBy) {
        currentOrder = sortBy
        let ascending = sortBy == .oldestToNewest
        let sortDescriptorByDate = NSSortDescriptor(key: "startDate", ascending: ascending)
        resultsController.sortDescriptors = [sortDescriptorByDate]
        paginationTracker.resync(reason: Self.reorderReason) {}
    }

    func updateFilters(_ filters: BookingFiltersViewModel.Filters) {
        hasFilters = filters.numberOfActiveFilters > 0
        self.filters = tabDateFilters.mergingDates(with: filters.bookingFilters)
        resultsController.predicate = currentPredicate
        paginationTracker.resync(reason: Self.refreshCacheReason) {}
    }

    /// Converts SortBy to BookingsRemote.Order
    private func remoteOrder(from sortBy: SortBy) -> BookingsRemote.Order {
        sortBy == .oldestToNewest ? .ascending : .descending
    }

    private var currentPredicate: NSPredicate {
        NSPredicate.createBookingPredicate(siteID: siteID, filters: filters)
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
            filters: filters,
            order: remoteOrder(from: currentOrder),
            shouldClearCache: shouldClearCache
        ) { [weak self] result in
            switch result {
            case .success(let hasNextPage):
                onCompletion?(.success(hasNextPage))

            case .failure(let error):
                self?.analytics.track(event: .BookingList.failedToFetchBookings(error))
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

extension BookingListViewModel {
    enum SortBy: Int, CaseIterable {
        case newestToOldest
        case oldestToNewest

        var title: String {
            switch self {
            case .newestToOldest: Localization.newestToOldest
            case .oldestToNewest: Localization.oldestToNewest
            }
        }

        enum Localization {
            static let newestToOldest = NSLocalizedString(
                "bookingList.sort.newestToOldest",
                value: "Date: Newest to Oldest",
                comment: "Option to sort bookings from newest to oldest"
            )
            static let oldestToNewest = NSLocalizedString(
                "bookingList.sort.oldestToNewest",
                value: "Date: Oldest to Newest",
                comment: "Option to sort bookings from oldest to newest"
            )
        }
    }
}
