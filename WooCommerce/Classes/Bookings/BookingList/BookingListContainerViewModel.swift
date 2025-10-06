import Foundation

/// View model for `BookingListContainerView`
final class BookingListContainerViewModel: ObservableObject {
    private let todayListViewModel: BookingListViewModel
    private let upcomingListViewModel: BookingListViewModel
    private let allListViewModel: BookingListViewModel

    @Published var selectedTab: BookingListTab = .today

    init(siteID: Int64) {
        self.todayListViewModel = BookingListViewModel(siteID: siteID, type: .today)
        self.upcomingListViewModel = BookingListViewModel(siteID: siteID, type: .upcoming)
        self.allListViewModel = BookingListViewModel(siteID: siteID, type: .all)
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
        case .upcoming, .all:
            return Localization.EmptyState.upcomingTitle
        }
    }

    func emptyStateDescription(hasFilters: Bool) -> String {
        guard !hasFilters else {
            return Localization.EmptyState.filterDescription
        }
        switch self {
        case .today:
            return Localization.EmptyState.todayDescription
        case .upcoming, .all:
            return Localization.EmptyState.upcomingDescription
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
                "bookingListView.emptyState.today.description",
                value: "You don't have any appointments or events scheduled for today.",
                comment: "Description for the empty state when no bookings for today is found"
            )
            static let upcomingTitle = NSLocalizedString(
                "bookingListView.emptyState.upcoming.title",
                value: "No upcoming bookings",
                comment: "Title for the empty state when there's no bookings for today"
            )
            static let upcomingDescription = NSLocalizedString(
                "bookingListView.emptyState.upcoming.description",
                value: "You don't have any future appointments or events scheduled yet.",
                comment: "Description for the empty state when there's no upcoming bookings"
            )
            static let filterTitle = NSLocalizedString(
                "bookingListView.emptyState.filter.title",
                value: "No bookings found",
                comment: "Title for the empty state when there's no bookings for the given filter"
            )
            static let filterDescription = NSLocalizedString(
                "bookingListView.emptyState.filter.description",
                value: "No bookings match your filters. Try adjusting them to see more results.",
                comment: "Description for the empty state when there's no bookings for the given filter"
            )
        }
    }
}
