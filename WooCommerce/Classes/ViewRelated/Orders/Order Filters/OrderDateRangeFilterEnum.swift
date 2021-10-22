import Foundation

/// Represents all of the possible Order Date Ranges in enum form
///
enum OrderDateRangeFilterEnum: Hashable {
    case today
    case last2Days
    case thisWeek
    case thisMonth
    case custom
}
