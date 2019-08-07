import Yosemite

extension StatsTimeRangeV4 {
    // TODO-jc: more calculation later
    var intervalQuantity: Int {
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

    func earliestDate(latestDate: Date) -> Date {
        let numberOfSeconds: TimeInterval
        let numberOfIntervals = intervalQuantity
        switch intervalGranularity {
        case .hourly:
            numberOfSeconds = 3600 * Double(numberOfIntervals)
        case .daily:
            numberOfSeconds = 86400 * Double(numberOfIntervals)
        case .weekly:
            numberOfSeconds = 86400 * 7 * Double(numberOfIntervals)
        case .monthly:
            numberOfSeconds = 86400 * 7 * 30 * Double(numberOfIntervals)
        default:
            fatalError("This case is not supported: \(intervalGranularity.rawValue)")
        }
        return latestDate.addingTimeInterval(-numberOfSeconds)
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
