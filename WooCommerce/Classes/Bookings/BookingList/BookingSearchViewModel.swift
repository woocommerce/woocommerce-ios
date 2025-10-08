import Foundation
import SwiftUI
import Yosemite
import Combine

/// View model for booking search functionality
final class BookingSearchViewModel: ObservableObject {

    @Published private(set) var searchResults: [Booking] = []

    @Published private(set) var isSearching = false

    @Published var errorFetching = false

    private let siteID: Int64
    private let type: BookingListTab
    private let stores: StoresManager
    private let currentDate: Date
    private var searchQuerySubscription: AnyCancellable?

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Supports infinite scroll for search results.
    private let searchPaginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Current search query
    @Published var currentSearchQuery: String = ""

    var emptyStateMessage: AttributedString {
        let quotedSearchQuery = "\"\(currentSearchQuery)\""
        let content = String.localizedStringWithFormat(Localization.emptySearchText, quotedSearchQuery)

        var attributedText = AttributedString(content)
        attributedText.font = .headline.weight(.regular)
        attributedText.foregroundColor = Color(.text)

        if let range = attributedText.range(of: quotedSearchQuery) {
            let textStyleContainer = AttributeContainer()
                .font(.headline.weight(.semibold))
                .foregroundColor(Color(.text))
            attributedText[range].setAttributes(textStyleContainer)
        }

        return attributedText
    }

    init(siteID: Int64,
         type: BookingListTab,
         searchQueryPublisher: AnyPublisher<String, Never>,
         stores: StoresManager = ServiceLocator.stores,
         currentDate: Date = Date()) {
        self.siteID = siteID
        self.type = type
        self.stores = stores
        self.currentDate = currentDate
        self.searchPaginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

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
                if query.isEmpty {
                    self.searchResults = []
                    self.isSearching = false
                } else {
                    self.isSearching = true
                    self.searchPaginationTracker.syncFirstPage()
                }
            }
    }
}

extension BookingSearchViewModel: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        defer {
            isSearching = false
            shouldShowBottomActivityIndicator = false
        }

        guard !currentSearchQuery.isEmpty else {
            onCompletion?(.success(false))
            return
        }

        if pageNumber == pageFirstIndex {
            searchResults = [] // Clear previous search results
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
            startDateBefore: type.startDateBefore(currentDate: currentDate)?.ISO8601Format(),
            startDateAfter: type.startDateAfter(currentDate: currentDate)?.ISO8601Format()
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let bookings):
                if pageNumber == self.pageFirstIndex {
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
        }
        stores.dispatch(action)
    }
}

private extension BookingSearchViewModel {
    enum Localization {
        static let emptySearchText = NSLocalizedString(
            "bookingList.emptySearchText",
            value: "We're sorry, we couldn't find results for %1$@",
            comment: "Message displayed when searching bookings by keyword yields no results. " +
            "The placeholder is the search keyword."
        )
    }
}
