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

    func latestDate(currentDate: Date) -> Date {
        switch self {
        case .today:
            return currentDate.endOfDay
        case .thisWeek:
            return currentDate.endOfWeek
        case .thisMonth:
            return currentDate.endOfMonth
        case .thisYear:
            return currentDate.endOfYear
        }
    }

    func earliestDate(latestDate: Date) -> Date {
        switch self {
        case .today:
            return latestDate.startOfDay
        case .thisWeek:
            return latestDate.startOfWeek
        case .thisMonth:
            return latestDate.startOfMonth
        case .thisYear:
            return latestDate.startOfYear
        }
    }

    var chartDateFormatter: DateFormatter {
        switch intervalGranularity {
        case .hourly:
            return DateFormatter.Charts.chartAxisHourFormatter
        case .daily:
            return DateFormatter.Charts.chartAxisDayFormatter
        case .weekly:
            return DateFormatter.Charts.chartAxisDayFormatter
        case .monthly:
            return DateFormatter.Charts.chartAxisMonthFormatter
        default:
            fatalError("This case is not supported: \(intervalGranularity.rawValue)")
        }
    }
}
