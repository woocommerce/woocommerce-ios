import Foundation
import Combine
import Yosemite

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

    @Published var selectedTab: BookingListTab = .today
    @Published var searchQuery: String = ""
    @Published var sortBy: BookingListViewModel.SortBy = .newestToOldest
    @Published var numberOfActiveFilters: Int = 0

    private let searchQuerySubject = PassthroughSubject<String, Never>()
    private var searchQuerySubscription: AnyCancellable?
    private var sortBySubscription: AnyCancellable?


    private var filters = BookingFiltersViewModel.Filters()

    var filterText: String {
        numberOfActiveFilters == 0 ? Localization.filter : String.localizedStringWithFormat(Localization.filterWithCount, numberOfActiveFilters)
    }

    var filterViewModel: BookingFiltersViewModel {
        BookingFiltersViewModel(filter: filters, siteID: siteID)
    }

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores

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
    }

    func pullToRefresh() async {
        async let today = todayListViewModel.onRefreshAction()
        async let upcoming = upcomingListViewModel.onRefreshAction(reason: "pull-to-refresh")
        async let all = allListViewModel.onRefreshAction(reason: "pull-to-refresh")
        _ = await (today, upcoming, all)
    }

    func listViewModel(for tab: BookingListTab) -> BookingListViewModel {



        todayListViewModel.parent = self
        upcomingListViewModel.parent = self
        allListViewModel.parent = self

        switch tab {
        case .today:
            return todayListViewModel
        case .upcoming:
            return upcomingListViewModel
        case .all:
            return allListViewModel
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
        guard selectedTab == .all else { return }
        self.filters = filters
        self.numberOfActiveFilters = filters.numberOfActiveFilters
        allListViewModel.updateFilters(filters)
        allSearchViewModel.updateFilters(filters)
        if shouldPersist {
            saveFilters(filters)
        }
    }

    func clearFilters() {
        guard selectedTab == .all else { return }
        let filters = BookingFiltersViewModel.Filters()
        updateFilters(filters)
    }
}

private extension BookingListContainerViewModel {
    func restorePersistedFilters() {
        Task { @MainActor in
            guard let storedFilters = await loadPersistedFilters() else {
                return
            }
            let filters = BookingFiltersViewModel.Filters(
                teamMembers: storedFilters.teamMembers,
                products: storedFilters.products,
                attendanceStatuses: storedFilters.attendanceStatuses,
                customers: storedFilters.customers,
                dateRange: storedFilters.dateRange,
                numberOfActiveFilters: storedFilters.numberOfActiveFilters
            )
            updateFilters(filters, shouldPersist: false)
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
            attendanceStatuses: filters.attendanceStatuses,
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

    func startDateBefore(currentDate: Date) -> Date? {
        switch self {
        case .today: currentDate.endOfDay(timezone: Self.utcTimeZone).addingTimeInterval(1)
        case .upcoming, .all: nil
        }
    }

    func startDateAfter(currentDate: Date) -> Date? {
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
