import Combine
import EventHorizonSDK
import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `BookingListContainerView`
final class BookingListContainerViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager

    private let todayListViewModel: BookingListViewModel
    private let upcomingListViewModel: BookingListViewModel
    private let allListViewModel: BookingListViewModel

    private let todaySearchViewModel: BookingSearchViewModel
    private let upcomingSearchViewModel: BookingSearchViewModel
    private let allSearchViewModel: BookingSearchViewModel

    private static let defaultTab: BookingListTab = .today
    @Published private(set) var selectedTab: BookingListTab = BookingListContainerViewModel.defaultTab
    @Published var searchQuery: String = ""
    @Published var sortBy: BookingListViewModel.SortBy = .newestToOldest
    @Published var numberOfActiveFilters: Int = 0
    private var hasUserSwitchedTab = false
    var hasRestoredFilters = false

    private let searchQuerySubject = PassthroughSubject<String, Never>()
    private var searchQuerySubscription: AnyCancellable?
    private var sortBySubscription: AnyCancellable?
    private let analytics: Analytics

    private lazy var allTabViewModels: [BookingListViewModel] = [
        todayListViewModel,
        upcomingListViewModel,
        allListViewModel
    ]

    private lazy var allSearchViewModels: [BookingSearchViewModel] = [
        todaySearchViewModel,
        upcomingSearchViewModel,
        allSearchViewModel
    ]

    private var filters = BookingFiltersViewModel.Filters()

    var filterText: String {
        numberOfActiveFilters == 0 ? Localization.filter : String.localizedStringWithFormat(Localization.filterWithCount, numberOfActiveFilters)
    }

    var filterViewModel: BookingFiltersViewModel {
        BookingFiltersViewModel(filter: filters, siteID: siteID)
    }

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics

        let searchQueryPublisher = searchQuerySubject.eraseToAnyPublisher()
        self.todayListViewModel = BookingListViewModel(
            siteID: siteID,
            type: .today,
        )
        self.upcomingListViewModel = BookingListViewModel(
            siteID: siteID,
            type: .upcoming,
        )
        self.allListViewModel = BookingListViewModel(
            siteID: siteID,
            type: .all,
        )

        self.todaySearchViewModel = BookingSearchViewModel(
            siteID: siteID,
            type: .today,
            searchQueryPublisher: searchQueryPublisher
        )
        self.upcomingSearchViewModel = BookingSearchViewModel(
            siteID: siteID,
            type: .upcoming,
            searchQueryPublisher: searchQueryPublisher
        )
        self.allSearchViewModel = BookingSearchViewModel(
            siteID: siteID,
            type: .all,
            searchQueryPublisher: searchQueryPublisher
        )

        searchQuerySubscription = $searchQuery
            .sink { [weak self] query in
                self?.searchQuerySubject.send(query)
            }

        sortBySubscription = $sortBy
            .removeDuplicates()
            .sink { [weak self] sortBy in
                guard let self else { return }
                todayListViewModel.updateSortOrder(sortBy)
                upcomingListViewModel.updateSortOrder(sortBy)
                allListViewModel.updateSortOrder(sortBy)
                todaySearchViewModel.updateSortOrder(sortBy)
                upcomingSearchViewModel.updateSortOrder(sortBy)
                allSearchViewModel.updateSortOrder(sortBy)
            }

        restorePersistedFilters()

        todayListViewModel.refreshCoordinator = self
        upcomingListViewModel.refreshCoordinator = self
        allListViewModel.refreshCoordinator = self
    }

    func listViewModel(for tab: BookingListTab) -> BookingListViewModel {
        switch tab {
        case .today:
            todayListViewModel
        case .upcoming:
            upcomingListViewModel
        case .all:
            allListViewModel
        }
    }

    func searchViewModel(for tab: BookingListTab) -> BookingSearchViewModel {
        switch tab {
        case .today:
            todaySearchViewModel
        case .upcoming:
            upcomingSearchViewModel
        case .all:
            allSearchViewModel
        }
    }

    func updateFilters(_ filters: BookingFiltersViewModel.Filters, shouldPersist: Bool = true) {
        self.filters = filters
        self.numberOfActiveFilters = filters.numberOfActiveFilters
        allTabViewModels.forEach { $0.updateFilters(filters) }
        allSearchViewModels.forEach { $0.updateFilters(filters) }
        if shouldPersist {
            saveFilters(filters)
        }
    }

    func clearFilters() {
        let filters = BookingFiltersViewModel.Filters()
        updateFilters(filters)
    }

    func setSelectedTab(to newTab: BookingListTab) {
        hasUserSwitchedTab = true
        selectedTab = newTab
        analytics.track(BookingListTabSelectEvent(selectedTab: newTab.analyticsValue))
        // Manually trigger onAppear as we are programaticcaly
        // changing the tab which will not trigger
        // onAppear on the View.
        onAppear()
    }

    func onAppear() {
        guard hasRestoredFilters else { return }
        let tabViewModel = listViewModel(for: selectedTab)
        analytics.track(BookingListViewEvent(
            selectedTab: selectedTab.analyticsValue,
            isDefaultTab: !hasUserSwitchedTab && selectedTab == Self.defaultTab,
            isListEmpty: tabViewModel.bookings.isEmpty,
            isFiltered: tabViewModel.hasFilters
        ))
    }

    func selectedBookingChanged() {
        let tabViewModel = listViewModel(for: selectedTab)
        let searchViewModel = searchViewModel(for: selectedTab)
        analytics.track(BookingListBookingTapEvent(
            selectedTab: selectedTab.analyticsValue,
            isSearchActive: !searchViewModel.currentSearchQuery.isEmpty,
            isFilteringActive: tabViewModel.hasFilters))
    }

    func filtersTapped() {
        analytics.track(BookingListFiltersTapEvent())
    }

    func applyFiltersTapped() {
        analytics.track(BookingListApplyFiltersEvent(selectedFilters: filters.analyticsFilterString))
    }

    func searchTapped() {
        analytics.track(BookingListSearchTapEvent())
    }

    func sortByTapped() {
        analytics.track(BookingListSortByTapEvent())
    }

    func sortByOptionSelected(_ option: BookingListViewModel.SortBy) {
        sortBy = option
        analytics.track(BookingListSortByOptionTapEvent(sortOption: option.analyticsValue))
    }
}

private extension BookingListContainerViewModel {
    func restorePersistedFilters() {
        Task { @MainActor in
            guard let storedFilters = await loadPersistedFilters() else {
                hasRestoredFilters = true
                onAppear()
                return
            }
            let filters = BookingFiltersViewModel.Filters(
                teamMembers: storedFilters.teamMembers,
                products: storedFilters.products,
                attendanceStatus: storedFilters.attendanceStatus,
                customers: storedFilters.customers,
                dateRange: storedFilters.dateRange,
                numberOfActiveFilters: storedFilters.numberOfActiveFilters
            )
            updateFilters(filters, shouldPersist: false)
            hasRestoredFilters = true
            onAppear()
        }
    }

    /// Loads persisted booking filters from AppSettings.
    /// Returns the loaded filters, or nil if none are persisted.
    @MainActor
    func loadPersistedFilters() async -> StoredBookingFilters.Filters? {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadBookingFilters(siteID: siteID) { result in
                if case .success(let filters) = result {
                    continuation.resume(returning: filters)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            stores.dispatch(action)
        }
    }

    /// Saves booking filters to AppSettings for persistence.
    private func saveFilters(_ filters: BookingFiltersViewModel.Filters) {
        let persistedFilters = StoredBookingFilters.Filters(
            teamMembers: filters.teamMembers,
            products: filters.products,
            attendanceStatus: filters.attendanceStatus,
            customers: filters.customers,
            dateRange: filters.dateRange
        )
        let action = AppSettingsAction.upsertBookingFilters(siteID: siteID, filters: persistedFilters) { error in
            if let error = error {
                DDLogError("⛔️ Error saving booking filters: \(error)")
            }
        }
        stores.dispatch(action)
    }
}

extension BookingListContainerViewModel: BookingListsRefreshCoordinating {
    @MainActor
    func refreshAllLists() async {
        await withCheckedContinuation { continuation in
            let action = BookingAction.clearBookingsCache(siteID: siteID) {
                continuation.resume()
            }
            stores.dispatch(action)
        }

        // Launch all tab refreshes in parallel and wait for all to complete
        await withTaskGroup(of: Void.self) { group in
            for viewModel in allTabViewModels {
                group.addTask { @MainActor in
                    await viewModel.reloadData(
                        reason: BookingListViewModel.siblingRefreshReason
                    )
                }
            }
        }
    }
}

private extension BookingListContainerViewModel {
    enum Localization {
        static let filter = NSLocalizedString(
            "bookingListView.filter",
            value: "Filter",
            comment: "Button to filter the booking list"
        )
        static let filterWithCount = NSLocalizedString(
            "bookingListView.filter.withCount",
            value: "Filter (%1$d)",
            comment: "Button to filter the booking list with number of active filters"
        )
    }
}

enum BookingListTab: Int, CaseIterable {
    case today
    case upcoming
    case all

    static let utcTimeZone: TimeZone = {
        guard let timeZone = TimeZone(identifier: "UTC") else {
            fatalError("Unable to set up UTC time zone")
        }
        return timeZone
    }()

    var title: String {
        switch self {
        case .today: Localization.today
        case .upcoming: Localization.upcoming
        case .all: Localization.all
        }
    }

    /// Filters sent to the remote API (date range boundaries and status exclusions per tab).
    func remoteFilters(currentDate: Date) -> BookingFilters {
        BookingFilters(
            startDateBefore: startDateBefore(currentDate: currentDate)?.ISO8601Format(),
            startDateAfter: startDateAfter(currentDate: currentDate)?.ISO8601Format(),
            bookingStatusExclude: bookingStatusExclude
        )
    }

    private var bookingStatusExclude: [String] {
        switch self {
        case .today, .upcoming:
            [BookingStatus.cancelled.rawValue]
        case .all:
            []
        }
    }

    private func startDateBefore(currentDate: Date) -> Date? {
        switch self {
        case .today: currentDate.endOfDay(timezone: Self.utcTimeZone).addingTimeInterval(1)
        case .upcoming, .all: nil
        }
    }

    private func startDateAfter(currentDate: Date) -> Date? {
        switch self {
        case .today: currentDate.startOfDay(timezone: Self.utcTimeZone).addingTimeInterval(-1)
        case .upcoming: currentDate.endOfDay(timezone: Self.utcTimeZone)
        case .all: nil
        }
    }

    func emptyStateTitle(hasFilters: Bool) -> String {
        guard !hasFilters else {
            return Localization.EmptyState.filterTitle
        }
        switch self {
        case .today:
            return Localization.EmptyState.todayTitle
        case .upcoming:
            return Localization.EmptyState.upcomingTitle
        case .all:
            return Localization.EmptyState.allTitle
        }
    }

    func emptyStateDescription(hasFilters: Bool) -> String {
        guard !hasFilters else {
            return Localization.EmptyState.filterDescription
        }
        switch self {
        case .today:
            return Localization.EmptyState.todayDescription
        case .upcoming:
            return Localization.EmptyState.upcomingDescription
        case .all:
            return Localization.EmptyState.allDescription
        }
    }

    private enum Localization {
        static let today = NSLocalizedString(
            "bookingListView.today",
            value: "Today",
            comment: "Tab title for today's bookings"
        )
        static let upcoming = NSLocalizedString(
            "bookingListView.upcoming",
            value: "Upcoming",
            comment: "Tab title for upcoming bookings"
        )
        static let all = NSLocalizedString(
            "bookingListView.all",
            value: "All",
            comment: "Tab title for all bookings"
        )
        enum EmptyState {
            static let todayTitle = NSLocalizedString(
                "bookingListView.emptyState.today.title",
                value: "No bookings today",
                comment: "Title for the empty state when no bookings for today is found"
            )
            static let todayDescription = NSLocalizedString(
                "bookingListView.emptyState.today.description.i3",
                value: "Any bookings scheduled for today will appear here.",
                comment: "Description for the empty state when no bookings for today is found"
            )
            static let upcomingTitle = NSLocalizedString(
                "bookingListView.emptyState.upcoming.title",
                value: "No upcoming bookings",
                comment: "Title for the empty state when there's no bookings for today"
            )
            static let upcomingDescription = NSLocalizedString(
                "bookingListView.emptyState.upcoming.description.i3",
                value: "New bookings will appear here as customers schedule your services or register for events.",
                comment: "Description for the empty state when there's no upcoming bookings"
            )
            static let allTitle = NSLocalizedString(
                "bookingListView.emptyState.all.title",
                value: "No bookings yet",
                comment: "Title for the empty state when there's no bookings at all so far"
            )
            static let allDescription = NSLocalizedString(
                "bookingListView.emptyState.all.description",
                value: "Bookings will appear here once customers start scheduling your services or registering for events.",
                comment: "Description for the empty state when there's no bookings at all so far"
            )
            static let filterTitle = NSLocalizedString(
                "bookingListView.emptyState.filter.title",
                value: "No bookings found",
                comment: "Title for the empty state when there's no bookings for the given filters"
            )
            static let filterDescription = NSLocalizedString(
                "bookingListView.emptyState.filter.description.i3",
                value: "Try adjusting or clearing your filters to see more results.",
                comment: "Description for the empty state when there's no bookings for the given filters"
            )
        }
    }
}
