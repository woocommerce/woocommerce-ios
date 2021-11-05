import Foundation

/// Represents all of the possible Order Date Ranges in enum form + start and end date in case of custom dates
///
struct OrderDateRangeFilter: Equatable {
    var filter: OrderDateRangeFilterEnum
    var startDate: Date?
    var endDate: Date?
}

// MARK: - FilterType conformance
extension OrderDateRangeFilter: FilterType {
    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch filter {
        case .any:
            return NSLocalizedString("Any", comment: "Label for one of the filters in order date range")
        case .today:
            return NSLocalizedString("Today", comment: "Label for one of the filters in order date range")
        case .last2Days:
            return NSLocalizedString("Last 2 Days", comment: "Label for one of the filters in order date range")
        case .thisWeek:
            return NSLocalizedString("This Week", comment: "Label for one of the filters in order date range")
        case .thisMonth:
            return NSLocalizedString("This Month", comment: "Label for one of the filters in order date range")
        case .custom:
            return NSLocalizedString("Custom Range", comment: "Label for one of the filters in order date range")
        }
    }

    var isActive: Bool {
        return true
    }
}

/// Represents all of the possible Order Date Ranges in enum form
///
enum OrderDateRangeFilterEnum: Hashable {
    case any
    case today
    case last2Days
    case thisWeek
    case thisMonth
    case custom
}
