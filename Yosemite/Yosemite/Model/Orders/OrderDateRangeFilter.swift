import Foundation

/// Represents all of the possible Order Date Ranges in enum form + start and end date in case of custom dates
///
public struct OrderDateRangeFilter: Codable, Equatable {
    public var filter: OrderDateRangeFilterEnum
    public var startDate: Date?
    public var endDate: Date?

    public init(filter: OrderDateRangeFilterEnum,
         startDate: Date? = nil,
         endDate: Date? = nil) {
        self.filter = filter
        self.startDate = startDate
        self.endDate = endDate
    }

    enum CodingKeys: String, CodingKey {
        case filter
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

/// Represents all of the possible Order Date Ranges in enum form
///
public enum OrderDateRangeFilterEnum: Codable, Hashable, CaseIterable {
    case any
    case today
    case last2Days
    case last7Days
    case last30Days
    case custom

    enum CodingKeys: String, CodingKey {
        case any
        case today
        case last2Days = "last_2_days"
        case last7Days = "last_7_days"
        case last30Days = "last_30_days"
        case custom
    }
}
