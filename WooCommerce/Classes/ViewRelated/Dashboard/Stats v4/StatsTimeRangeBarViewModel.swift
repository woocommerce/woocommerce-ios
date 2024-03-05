import Experiments
import Yosemite

private extension StatsTimeRangeV4 {
    func timeRangeText(startDate: Date, endDate: Date, selectedDate: Date, timezone: TimeZone) -> String {
        timeRangeSelectedDateFormatter(timezone: timezone)
            .string(from: selectedDate)
    }

    func timeRangeText(startDate: Date, endDate: Date, timezone: TimeZone) -> String {
        let dateFormatter = timeRangeDateFormatter(timezone: timezone)
        switch self {
        case .today, .thisMonth, .thisYear:
            return dateFormatter.string(from: startDate)
        case .thisWeek:
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            let format = NSLocalizedString("%1$@ - %2$@", comment: "Displays a date range for a stats interval")
            return String.localizedStringWithFormat(format, startDateString, endDateString)
        case let .custom(customStartDate, customEndDate):
            // Always display the exact date for custom range.
            let startDateString = dateFormatter.string(from: customStartDate)
            let endDateString = dateFormatter.string(from: customEndDate)
            let format = NSLocalizedString("%1$@ - %2$@", comment: "Displays a date range for a custom stats interval")
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
            dateFormatter = DateFormatter.Charts.chartAxisFullMonthFormatter
        case .thisYear:
            dateFormatter = DateFormatter.Charts.chartAxisYearFormatter
        case .custom:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            dateFormatter = formatter
        }
        dateFormatter.timeZone = timezone
        return dateFormatter
    }

    /// Date formatter for a selected date for a time range.
    func timeRangeSelectedDateFormatter(timezone: TimeZone) -> DateFormatter {
        let dateFormatter: DateFormatter
        switch intervalGranularity {
        case .hourly:
            dateFormatter = DateFormatter.Charts.chartSelectedDateHourFormatter
        case .daily, .weekly:
            dateFormatter = DateFormatter.Charts.chartAxisDayFormatter
        case .monthly, .quarterly, .yearly:
            dateFormatter = DateFormatter.Charts.chartAxisFullMonthFormatter
        }
        dateFormatter.timeZone = timezone
        return dateFormatter
    }
}

/// View model for `StatsTimeRangeBarView`.
struct StatsTimeRangeBarViewModel: Equatable {
    let timeRangeText: String
    let isTimeRangeEditable: Bool

    init(startDate: Date,
         endDate: Date,
         timeRange: StatsTimeRangeV4,
         timezone: TimeZone) {
        isTimeRangeEditable = timeRange.isCustomTimeRange
        timeRangeText = timeRange.timeRangeText(startDate: startDate,
                                                endDate: endDate,
                                                timezone: timezone)
    }

    init(startDate: Date,
         endDate: Date,
         selectedDate: Date,
         timeRange: StatsTimeRangeV4,
         timezone: TimeZone) {
        // Disable editing time range when selecting a specific date on the graph
        isTimeRangeEditable = false
        timeRangeText = timeRange.timeRangeText(startDate: startDate,
                                                endDate: endDate,
                                                selectedDate: selectedDate,
                                                timezone: timezone)
    }
}
