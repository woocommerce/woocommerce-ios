import Foundation

/// Represents the time range for an Order Stats v4 model.
/// This is a local property and not in the remote response.
///
/// - today: hourly data starting midnight today until now.
/// - thisWeek: daily data starting Sunday of this week until now.
/// - thisMonth: daily data starting 1st of this month until now.
/// - thisYear: monthly data starting January of this year until now.
/// - custom: Data for a custom date range.
public enum StatsTimeRangeV4: Sendable {
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case custom(from: Date, to: Date)
}

extension StatsTimeRangeV4: RawRepresentable, Hashable {

    public init?(rawValue: String) {
        switch rawValue {
        case Value.today:
            self = .today
        case Value.thisWeek:
            self = .thisWeek
        case Value.thisMonth:
            self = .thisMonth
        case Value.thisYear:
            self = .thisYear
        default:
            guard let dates = CustomRangeFormatter.dates(from: rawValue) else {
                return nil
            }

            self = .custom(from: dates.from, to: dates.to)
        }
    }

    public var rawValue: String {
        switch self {
        case .today: return Value.today
        case .thisWeek: return Value.thisWeek
        case .thisMonth: return Value.thisMonth
        case .thisYear: return Value.thisYear
        case .custom(let from, let to):
            return CustomRangeFormatter.rangeFrom(from: from, to: to)
        }
    }

    public var isCustomTimeRange: Bool {
        switch self {
        case .today, .thisWeek, .thisMonth, .thisYear:
            false
        case .custom:
            true
        }
    }

    private enum CustomRangeFormatter {
        static private let dateFormatter = DateFormatter.Defaults.yearMonthDayDateFormatter
        static private let separator = "_"

        static func rangeFrom(from: Date, to: Date) -> String {
            [Value.custom,
             dateFormatter.string(from: from),
             dateFormatter.string(from: to)].joined(separator: separator)
        }

        static func dates(from rawValue: String) -> (from: Date, to: Date)? {
            guard rawValue.starts(with: Value.custom) else {
                return nil
            }

            let splits = rawValue.split(separator: separator)

            guard let from = splits[safe: 1],
                  let to = splits[safe: 2] else {
                return nil
            }

            guard let fromDate = dateFormatter.date(from: String(from)),
                  let toDate = dateFormatter.date(from: String(to)) else {
                return nil
            }

            return (from: fromDate, to: toDate)
        }
    }

    private enum Value {
        static let today = "today"
        static let thisWeek = "thisWeek"
        static let thisMonth = "thisMonth"
        static let thisYear = "thisYear"
        static let custom = "custom"
    }
}

extension StatsTimeRangeV4 {
    /// Represents the period unit of the store stats using Stats v4 API given a time range.
    public var intervalGranularity: StatsGranularityV4 {
        switch self {
        case .today:
            return .hourly
        case .thisWeek:
            return .daily
        case .thisMonth:
            return .daily
        case .thisYear:
            return .monthly
        case .custom(let from, let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
                return .hourly
            }
            switch differenceInDays {
            case .sameDay:
                return .hourly
            case .from1To28:
                return .daily
            case .from29To90:
                return .weekly
            case .from91daysTo3Years:
                return .monthly
            case .greaterThan3Years:
                return .yearly
            }
        }
    }

    /// Represents the period unit of the site visit stats given a time range.
    public var siteVisitStatsGranularity: StatGranularity {
        switch self {
        case .today, .thisWeek, .thisMonth:
            return .day
        case .thisYear:
            return .month
        case .custom(let from, let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
                return .day
            }
            switch differenceInDays {
            case .sameDay, .from1To28:
                return .day
            case .from29To90:
                return .week
            case .from91daysTo3Years:
                return .month
            case .greaterThan3Years:
                return .year
            }
        }
    }

    /// Represents the period unit of the top earners stats given a time range.
    public var topEarnerStatsGranularity: StatGranularity {
        switch self {
        case .today:
            return .day
        case .thisWeek:
            return .week
        case .thisMonth:
            return .month
        case .thisYear:
            return .year
        case .custom(let from, let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
                return .day
            }
            switch differenceInDays {
            case .sameDay, .from1To28:
                return .day
            case .from29To90:
                return .week
            case .from91daysTo3Years:
                return .month
            case .greaterThan3Years:
                return .year
            }
        }
    }

    /// Represents the period unit of the summary stats given a time range.
    public var summaryStatsGranularity: StatGranularity {
        switch self {
        case .today:
            return .day
        case .thisWeek:
            return .week
        case .thisMonth:
            return .month
        case .thisYear:
            return .year
        case .custom(let from, let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
                return .day
            }
            switch differenceInDays {
            case .sameDay, .from1To28:
                return .day
            case .from29To90:
                return .week
            case .from91daysTo3Years:
                return .month
            case .greaterThan3Years:
                return .year
            }
        }
    }

    /// The number of intervals for site visit stats to fetch given a time range.
    /// The interval unit is in `siteVisitStatsGranularity`.
    func siteVisitStatsQuantity(date: Date, siteTimezone: TimeZone) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone

        switch self {
        case .today:
            return 1
        case .thisWeek:
            return 7
        case .thisMonth:
            let daysThisMonth = calendar.range(of: .day, in: .month, for: date)
            return daysThisMonth?.count ?? 0
        case .thisYear:
            return 12
        case let .custom(start, end):
            switch siteVisitStatsGranularity {
            case .day:
                let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
                return difference + 1 // to include stats for both start and end date
            case .week:
                let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
                // Using days divided by 7 to calculate week difference because the week components in calendar are not applicable.
                return difference/7 + 1
            case .month:
                let difference = calendar.dateComponents([.month], from: start, to: end).month ?? 0
                return difference + 1
            case .year:
                let difference = calendar.dateComponents([.year], from: start, to: end).year ?? 0
                return difference + 1
            }
        }
    }

    /// If granularity of site stats and order stats are not equivalent,
    /// there can be discrepancy between site visit and order stats.
    /// Selecting visit stats is not supported in that case.
    ///
    public var shouldSupportSelectingVisitStats: Bool {
        switch (intervalGranularity, siteVisitStatsGranularity) {
        case (.daily, .day), (.weekly, .week), (.monthly, .month), (.yearly, .year):
            return true
        default:
            return false
        }
    }
}

public extension StatsTimeRangeV4 {
    enum DifferenceInDays {
        case greaterThan3Years
        case from91daysTo3Years
        case from29To90
        case from1To28
        case sameDay
    }

    /// Based on WooCommerce Core
    ///
    /// https://github.com/woocommerce/woocommerce/blob/e863c02551e94d928d3873131ff2f4ab61d0ff66/packages/js/date/src/index.ts#L626
    ///
    /// More details at pe5sF9-2ri-p2
    ///
    static func differenceInDays(startDate: Date, endDate: Date) -> DifferenceInDays? {
        let dateComponents = Calendar.current.dateComponents([.day], from: startDate, to: endDate)

        guard let day = dateComponents.day else {
            return nil
        }

        switch day {
        case 365*3+1...Int.max:
            return .greaterThan3Years
        case 91...365*3:
            return .from91daysTo3Years
        case 29...90:
            return .from29To90
        case 1...28:
            return .from1To28
        case 0:
            return .sameDay
        default:
            return nil
        }
    }

    /// Returns the latest date to be shown for the time range, given the current date and site time zone
    ///
    /// - Parameters:
    ///   - currentDate: the date which the latest date is based on
    ///   - siteTimezone: site time zone, which the stats data are based on
    func latestDate(currentDate: Date, siteTimezone: TimeZone) -> Date {
        switch self {
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
    func earliestDate(latestDate: Date, siteTimezone: TimeZone) -> Date {
        switch self {
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
