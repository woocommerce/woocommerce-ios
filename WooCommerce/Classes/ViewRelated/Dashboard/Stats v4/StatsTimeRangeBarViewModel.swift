import Yosemite

private extension StatsTimeRangeV4 {
    func timeRangeText(startDate: Date, endDate: Date, timezone: TimeZone) -> String {
        let dateFormatter = timeRangeDateFormatter(timezone: timezone)
        switch self {
        case .today, .thisMonth, .thisYear:
            return dateFormatter.string(from: startDate)
        case .thisWeek:
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            let format = NSLocalizedString("%1$@-%2$@", comment: "Displays a date range for a stats interval")
            return String.localizedStringWithFormat(format, startDateString, endDateString)
        }
    }

    func timeRangeDateFormatter(timezone: TimeZone) -> DateFormatter {
        let dateFormatter: DateFormatter
        switch self {
        case .today:
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
            dateFormatter = formatter
        case .thisWeek:
            dateFormatter = DateFormatter.Charts.chartAxisDayFormatter
        case .thisMonth:
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMMM")
            dateFormatter = formatter
        case .thisYear:
            dateFormatter = DateFormatter.Charts.chartAxisYearFormatter
        }
        dateFormatter.timeZone = timezone
        return dateFormatter
    }
}

/// View model for `StatsTimeRangeBarView`.
struct StatsTimeRangeBarViewModel {
    let timeRangeText: String

    init(startDate: Date,
         endDate: Date,
         timeRange: StatsTimeRangeV4,
         timezone: TimeZone) {
        timeRangeText = timeRange.timeRangeText(startDate: startDate,
                                                endDate: endDate,
                                                timezone: timezone)
    }
}
