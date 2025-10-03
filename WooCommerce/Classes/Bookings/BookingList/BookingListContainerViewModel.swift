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

    var startDateBefore: Date? {
        switch self {
        case .today: Date().endOfDay(timezone: Self.utcTimeZone)
        case .upcoming, .all: nil
        }
    }

    var startDateAfter: Date? {
        switch self {
        case .today: Date().startOfDay(timezone: Self.utcTimeZone)
        case .upcoming: Date().endOfDay(timezone: Self.utcTimeZone)
        case .all: nil
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
    }
}
