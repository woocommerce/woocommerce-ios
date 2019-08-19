import Yosemite

extension StatsTimeRangeV4 {
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

    /// The title of a time range tab.
    var tabTitle: String {
        switch self {
        case .today:
            return NSLocalizedString("Today", comment: "Tab selector title that shows the statistics for today")
        case .thisWeek:
            return NSLocalizedString("This Week", comment: "Tab selector title that shows the statistics for this week")
        case .thisMonth:
            return NSLocalizedString("This Month", comment: "Tab selector title that shows the statistics for this month")
        case .thisYear:
            return NSLocalizedString("This Year", comment: "Tab selector title that shows the statistics for this year")
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

    /// Returns a date formatter for the x-axis labels of a stats chart
    ///
    /// - Parameter siteTimezone: site time zone, which the stats data are based on
    func chartDateFormatter(siteTimezone: TimeZone) -> DateFormatter {
        let dateFormatter: DateFormatter
        switch intervalGranularity {
        case .hourly:
            dateFormatter = DateFormatter.Charts.chartAxisHourFormatter
        case .daily:
            dateFormatter = DateFormatter.Charts.chartAxisDayFormatter
        case .weekly:
            dateFormatter = DateFormatter.Charts.chartAxisDayFormatter
        case .monthly:
            dateFormatter = DateFormatter.Charts.chartAxisMonthFormatter
        default:
            fatalError("This case is not supported: \(intervalGranularity.rawValue)")
        }
        dateFormatter.timeZone = siteTimezone
        return dateFormatter
    }
}
