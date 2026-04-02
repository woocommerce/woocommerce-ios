import EventHorizonSDK
import enum Networking.BookingAttendanceStatus

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

// MARK: - Filter string computation (extracted from BookingList+Analytics.swift)

extension BookingFiltersViewModel.Filters {
    var analyticsFilterString: String {
        var appliedFilters = [String]()
        if attendanceStatus != nil {
            appliedFilters.append("attendance_status")
        }
        if bookingFilters.customerIDs.isNotEmpty {
            appliedFilters.append("customer")
        }
        if dateRange != nil {
            appliedFilters.append("date_time")
        }
        if products.isNotEmpty {
            appliedFilters.append("service_events")
        }
        if teamMembers.isNotEmpty {
            appliedFilters.append("team_member")
        }
        return appliedFilters.joined(separator: ",")
    }
}
