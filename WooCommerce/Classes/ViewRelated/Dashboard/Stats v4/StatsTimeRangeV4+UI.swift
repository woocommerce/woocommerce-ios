import Yosemite

extension StatsTimeRangeV4 {
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

    var tabTitle: String {
        switch self {
        case .today:
            return NSLocalizedString("Today", comment: "Tab selector title that shows the statistics of today")
        case .thisWeek:
            return NSLocalizedString("This Week", comment: "Tab selector title that shows the statistics of this week")
        case .thisMonth:
            return NSLocalizedString("This Month", comment: "Tab selector title that shows the statistics of this month")
        case .thisYear:
            return NSLocalizedString("This Year", comment: "Tab selector title that shows the statistics of this year")
        }
    }

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
