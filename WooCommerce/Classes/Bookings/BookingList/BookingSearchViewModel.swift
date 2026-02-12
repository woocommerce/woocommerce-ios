import Foundation
import SwiftUI
import Yosemite
import Combine
import class Networking.BookingsRemote

/// View model for booking search functionality
final class BookingSearchViewModel: ObservableObject {

    @Published private(set) var searchResults: [Booking] = []

    @Published private(set) var isSearching = false

    @Published var errorFetching = false

    private let siteID: Int64
    private let type: BookingListTab
    private let stores: StoresManager
    private var searchQuerySubscription: AnyCancellable?
    private var currentOrder: BookingListViewModel.SortBy = .newestToOldest

    private let tabDateFilters: BookingFilters
    private var filters: BookingFilters

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Supports infinite scroll for search results.
    private let searchPaginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Current search query
    @Published var currentSearchQuery: String = ""

    init(siteID: Int64,
         type: BookingListTab,
         searchQueryPublisher: AnyPublisher<String, Never>,
         stores: StoresManager = ServiceLocator.stores,
         currentDate: Date = Date()) {
        self.siteID = siteID
        self.type = type
        self.stores = stores
        self.searchPaginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

        self.tabDateFilters = BookingFilters(
            startDateBefore: type.startDateBefore(currentDate: currentDate)?.ISO8601Format(),
            startDateAfter: type.startDateAfter(currentDate: currentDate)?.ISO8601Format()
        )
        self.filters = tabDateFilters

        configureSearchPaginationTracker()
        configureSearchQuerySubscription(searchQueryPublisher: searchQueryPublisher)
    }

    /// Called when the user pulls down the list to refresh.
    @MainActor
    func onRefreshAction() async {
        await withCheckedContinuation { continuation in
            searchPaginationTracker.resync(reason: nil) {
                continuation.resume(returning: ())
            }
        }
    }

    /// Called when the next page should be loaded.
    func onLoadNextPageAction() {
        guard !currentSearchQuery.isEmpty else { return }
        searchPaginationTracker.ensureNextPageIsSynced()
    }

    /// Updates the sort order for search results.
    func updateSortOrder(_ sortBy: BookingListViewModel.SortBy) {
        currentOrder = sortBy
        // Trigger a new search if we have a query
        if !currentSearchQuery.isEmpty {
            searchPaginationTracker.syncFirstPage()
        }
    }

    func updateFilters(_ filters: BookingFiltersViewModel.Filters) {
        self.filters = tabDateFilters.mergingDates(with: filters.bookingFilters)
        searchPaginationTracker.resync(reason: nil) {}
    }

    /// Converts SortBy to BookingsRemote.Order
    private func remoteOrder(from sortBy: BookingListViewModel.SortBy) -> BookingsRemote.Order {
        sortBy == .oldestToNewest ? .ascending : .descending
    }
}

// MARK: Configuration

private extension BookingSearchViewModel {
    func configureSearchPaginationTracker() {
        searchPaginationTracker.delegate = self
    }

    /// Configures subscription to search query changes.
    func configureSearchQuerySubscription(searchQueryPublisher: AnyPublisher<String, Never>) {
        searchQueryPublisher
            .removeDuplicates()
            .assign(to: &$currentSearchQuery)

        searchQuerySubscription = $currentSearchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                isSearching = true
                if query.isEmpty {
                    searchResults = []
                } else {
                    searchPaginationTracker.syncFirstPage()
                }
            }
    }
}

extension BookingSearchViewModel: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        guard !currentSearchQuery.isEmpty else {
            onCompletion?(.success(false))
            isSearching = false
            shouldShowBottomActivityIndicator = false
            return
        }

        shouldShowBottomActivityIndicator = true
        withAnimation {
            errorFetching = false
        }

        let action = BookingAction.searchBookings(
            siteID: siteID,
            searchQuery: currentSearchQuery,
            pageNumber: pageNumber,
            pageSize: pageSize,
            filters: filters,
            order: remoteOrder(from: currentOrder)
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let bookings):
                if pageNumber == pageFirstIndex {
                    searchResults = bookings
                } else {
                    searchResults.append(contentsOf: bookings)
                }
                let hasNextPage = bookings.count == pageSize
                onCompletion?(.success(hasNextPage))

            case .failure(let error):
                DDLogError("⛔️ Error searching bookings: \(error)")
                withAnimation {
                    self.errorFetching = true
                }
                onCompletion?(.failure(error))
            }

            isSearching = false
            shouldShowBottomActivityIndicator = false
        }
        stores.dispatch(action)
    }
}
