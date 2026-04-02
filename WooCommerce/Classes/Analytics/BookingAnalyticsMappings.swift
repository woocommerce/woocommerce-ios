import EventHorizonSDK
import enum Yosemite.BookingAttendanceStatus

// MARK: - App type → Generated analytics enum mappings

extension BookingListTab {
    var analyticsValue: BookingTabValue {
        switch self {
        case .today: .today
        case .upcoming: .upcoming
        case .all: .all
        }
    }
}

extension BookingListViewModel.SortBy {
    var analyticsValue: BookingSortValue {
        switch self {
        case .newestToOldest: .newestFirst
        case .oldestToNewest: .oldestFirst
        }
    }
}

extension BookingAttendanceStatus {
    var analyticsValue: BookingAttendanceValue {
        switch self {
        case .attended: .attended
        case .unattended: .unattended
        case .unknown: .unknown
        }
    }
}

// MARK: - Filter analytics

enum BookingFilterAnalyticsKey: String {
    case attendanceStatus = "attendance_status"
    case customer = "customer"
    case dateTime = "date_time"
    case serviceEvents = "service_events"
    case teamMember = "team_member"
}

extension BookingFiltersViewModel.Filters {
    var analyticsFilterString: String {
        var appliedFilters = [BookingFilterAnalyticsKey]()
        if attendanceStatus != nil {
            appliedFilters.append(.attendanceStatus)
        }
        if bookingFilters.customerIDs.isNotEmpty {
            appliedFilters.append(.customer)
        }
        if dateRange != nil {
            appliedFilters.append(.dateTime)
        }
        if products.isNotEmpty {
            appliedFilters.append(.serviceEvents)
        }
        if teamMembers.isNotEmpty {
            appliedFilters.append(.teamMember)
        }
        return appliedFilters.map(\.rawValue).joined(separator: ",")
    }
}
