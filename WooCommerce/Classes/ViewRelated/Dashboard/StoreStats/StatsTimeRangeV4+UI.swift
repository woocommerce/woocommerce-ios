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
        case .custom:
            // Returns maximum value allowed for pagination,
            // the plugin would return the maximum values available for the required granularity.
            // https://developer.wordpress.org/rest-api/using-the-rest-api/pagination/
            return 100
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
        case .custom:
            return NSLocalizedString(
                "statsTimeRangeV4.tabTitle.custom",
                value: "Custom Range",
                comment: "Tab selector title that shows the statistics for today"
            )
        }
    }
}
