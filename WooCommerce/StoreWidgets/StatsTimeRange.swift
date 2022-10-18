import Foundation
import WooFoundation
import enum Networking.StatGranularity
import enum Networking.StatsGranularityV4

/// Represents the time range for an Order Stats v4 model.
/// This is a local property and not in the remote response.
///
/// - today: hourly data starting midnight today until now.
/// - thisWeek: daily data starting Sunday of this week until now.
/// - thisMonth: daily data starting 1st of this month until now.
/// - thisYear: monthly data starting January of this year until now.
enum StatsTimeRange: String {
    case today
    case thisWeek
    case thisMonth
    case thisYear
}

extension StatsTimeRange {
    init(_ timeRange: IntentTimeRange) {
        switch timeRange {
        case .unknown, .today:
            self = .today
        case .thisWeek:
            self = .thisWeek
        case .thisMonth:
            self = .thisMonth
        case .thisYear:
            self = .thisYear
        }
    }

    /// The maximum number of stats intervals a time range could have.
    var maxNumberOfIntervals: Int {
        switch self {
        case .today:
            return 24
        case .thisWeek:
            return 7
        case .thisMonth:
            return 31
        case .thisYear:
            return 12
        }
    }

    /// Represents the period unit of the store stats using Stats v4 API given a time range.
    var intervalGranularity: StatsGranularityV4 {
        switch self {
        case .today:
            return .hourly
        case .thisWeek:
            return .daily
        case .thisMonth:
            return .daily
        case .thisYear:
            return .monthly
        }
    }

    /// Represents the period unit of the site visit stats given a time range.
    var siteVisitStatsGranularity: StatGranularity {
        switch self {
        case .today, .thisWeek, .thisMonth:
            return .day
        case .thisYear:
            return .month
        }
    }

    /// The number of intervals for site visit stats to fetch given a time range.
    /// The interval unit is in `siteVisitStatsGranularity`.
    func siteVisitStatsQuantity(date: Date, siteTimezone: TimeZone) -> Int {
        switch self {
        case .today:
            return 1
        case .thisWeek:
            return 7
        case .thisMonth:
            var calendar = Calendar.current
            calendar.timeZone = siteTimezone
            let daysThisMonth = calendar.range(of: .day, in: .month, for: date)
            return daysThisMonth?.count ?? 0
        case .thisYear:
            return 12
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
            return currentDate.endOfWeek(timezone: siteTimezone)
        case .thisMonth:
            return currentDate.endOfMonth(timezone: siteTimezone)
        case .thisYear:
            return currentDate.endOfYear(timezone: siteTimezone)
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
            return latestDate.startOfWeek(timezone: siteTimezone)
        case .thisMonth:
            return latestDate.startOfMonth(timezone: siteTimezone)
        case .thisYear:
            return latestDate.startOfYear(timezone: siteTimezone)
        }
    }
}
