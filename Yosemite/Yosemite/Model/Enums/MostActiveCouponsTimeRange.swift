import Foundation

/// Represents the time range for fetching most active coupons.
/// This is a local property and not in the remote response.
///
/// - allTime: All time data.
/// - today: hourly data starting midnight today until now.
/// - thisWeek: daily data starting Sunday of this week until now.
/// - thisMonth: daily data starting 1st of this month until now.
/// - thisYear: monthly data starting January of this year until now.
/// - custom: Data for a custom date range.
///
public enum MostActiveCouponsTimeRange {
    case allTime
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case custom(from: Date, to: Date)
}

extension MostActiveCouponsTimeRange: RawRepresentable, Hashable {

    public init?(rawValue: String) {
        switch rawValue {
        case Value.allTime:
            self = .allTime
        case Value.today:
            self = .today
        case Value.thisWeek:
            self = .thisWeek
        case Value.thisMonth:
            self = .thisMonth
        case Value.thisYear:
            self = .thisYear
        default:
            guard let dates = StatsTimeRangeV4.CustomRangeFormatter.dates(from: rawValue) else {
                return nil
            }

            self = .custom(from: dates.from, to: dates.to)
        }
    }

    public var rawValue: String {
        switch self {
        case .allTime: return Value.allTime
        case .today: return Value.today
        case .thisWeek: return Value.thisWeek
        case .thisMonth: return Value.thisMonth
        case .thisYear: return Value.thisYear
        case .custom(let from, let to):
            return StatsTimeRangeV4.CustomRangeFormatter.rangeFrom(from: from, to: to)
        }
    }

    public var isCustomTimeRange: Bool {
        switch self {
        case .allTime, .today, .thisWeek, .thisMonth, .thisYear:
            false
        case .custom:
            true
        }
    }

    private enum Value {
        static let allTime = "allTime"
        static let today = "today"
        static let thisWeek = "thisWeek"
        static let thisMonth = "thisMonth"
        static let thisYear = "thisYear"
        static let custom = "custom"
    }

    /// Returns the latest date to be shown for the time range, given the current date and site time zone
    ///
    /// - Parameters:
    ///   - currentDate: the date which the latest date is based on
    ///   - siteTimezone: site time zone, which the stats data are based on
    func latestDate(currentDate: Date, siteTimezone: TimeZone) -> Date? {
        switch self {
        case .allTime:
            return nil
        case .today:
            return currentDate.endOfDay(timezone: siteTimezone)
        case .thisWeek:
            return currentDate.endOfWeek(timezone: siteTimezone)!
        case .thisMonth:
            return currentDate.endOfMonth(timezone: siteTimezone)!
        case .thisYear:
            return currentDate.endOfYear(timezone: siteTimezone)!
        case .custom(_, let toDate):
            return toDate.endOfDay(timezone: siteTimezone)
        }
    }

    /// Returns the earliest date to be shown for the time range, given the latest date and site time zone
    ///
    /// - Parameters:
    ///   - latestDate: the date which the earliest date is based on
    ///   - siteTimezone: site time zone, which the stats data are based on
    func earliestDate(latestDate: Date, siteTimezone: TimeZone) -> Date? {
        switch self {
        case .allTime:
            return nil
        case .today:
            return latestDate.startOfDay(timezone: siteTimezone)
        case .thisWeek:
            return latestDate.startOfWeek(timezone: siteTimezone)!
        case .thisMonth:
            return latestDate.startOfMonth(timezone: siteTimezone)!
        case .thisYear:
            return latestDate.startOfYear(timezone: siteTimezone)!
        case .custom(let startDate, _):
            return startDate.startOfDay(timezone: siteTimezone)
        }
    }
}
