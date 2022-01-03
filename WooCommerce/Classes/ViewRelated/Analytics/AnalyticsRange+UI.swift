import Yosemite

extension AnalyticsRange {
    /// The maximum number of stats intervals a time range could have.
    var maxNumberOfIntervals: Int {
        switch self {
        case .today:
            return 24
        case .yesterday:
            return 24
        case .lastWeek:
            return 7
        case .lastMonth:
            return 31
        case .lastQuarter:
            return 4
        case .lastYear:
            return 12
        case .weekToDate:
            return 7
        case .monthToDate:
            return 31
        case .quarterToDate:
            return 4
        case .yearToDate:
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
        case .yesterday:
            return currentDate.endOfDay(timezone: siteTimezone)
        case .lastWeek:
            return currentDate.endOfWeek(timezone: siteTimezone)
        case .lastMonth:
            return currentDate.endOfMonth(timezone: siteTimezone)
        case .lastQuarter:
            return currentDate.endOfMonth(timezone: siteTimezone)
        case .lastYear:
            return currentDate.endOfYear(timezone: siteTimezone)
        case .weekToDate:
            return currentDate.endOfWeek(timezone: siteTimezone)
        case .monthToDate:
            return currentDate.endOfMonth(timezone: siteTimezone)
        case .quarterToDate:
            return currentDate.endOfMonth(timezone: siteTimezone)
        case .yearToDate:
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
        case .yesterday:
            return latestDate.startOfDay(timezone: siteTimezone)
        case .lastWeek:
            return latestDate.startOfWeek(timezone: siteTimezone)
        case .lastMonth:
            return latestDate.startOfMonth(timezone: siteTimezone)
        case .lastQuarter:
            return latestDate.startOfMonth(timezone: siteTimezone)
        case .lastYear:
            return latestDate.startOfYear(timezone: siteTimezone)
        case .weekToDate:
            return latestDate.startOfWeek(timezone: siteTimezone)
        case .monthToDate:
            return latestDate.startOfMonth(timezone: siteTimezone)
        case .quarterToDate:
            return latestDate.startOfMonth(timezone: siteTimezone)
        case .yearToDate:
            return latestDate.startOfYear(timezone: siteTimezone)
        }
    }
}
