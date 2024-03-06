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
        case .monthly:
            dateFormatter = DateFormatter.Charts.chartAxisFullMonthFormatter
        case .yearly:
            dateFormatter = DateFormatter.Charts.chartAxisYearFormatter
        }
        dateFormatter.timeZone = timezone
        return dateFormatter
    }
}

/// View model for `StatsTimeRangeBarView`.
struct StatsTimeRangeBarViewModel: Equatable {
    let timeRangeText: String
    let isTimeRangeEditable: Bool
    let granularityText: String?

    init(startDate: Date,
         endDate: Date,
         timeRange: StatsTimeRangeV4,
         timezone: TimeZone) {
        isTimeRangeEditable = timeRange.isCustomTimeRange
        granularityText = timeRange.isCustomTimeRange ? timeRange.intervalGranularity.displayText : nil
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
        granularityText = nil
        timeRangeText = timeRange.timeRangeText(startDate: startDate,
                                                endDate: endDate,
                                                selectedDate: selectedDate,
                                                timezone: timezone)
    }
}

extension StatsGranularityV4 {
    var displayText: String {
        switch self {
        case .daily:
            NSLocalizedString(
                "statsGranularityV4.daily",
                value: "By day",
                comment: "Display text for the daily granularity of store stats on the My Store screen"
            )
        case .hourly:
            NSLocalizedString(
                "statsGranularityV4.hourly",
                value: "By hour",
                comment: "Display text for the hourly granularity of store stats on the My Store screen"
            )
        case .weekly:
            NSLocalizedString(
                "statsGranularityV4.weekly",
                value: "By week",
                comment: "Display text for the weekly granularity of store stats on the My Store screen"
            )
        case .monthly:
            NSLocalizedString(
                "statsGranularityV4.monthly",
                value: "By month",
                comment: "Display text for the monthly granularity of store stats on the My Store screen"
            )
        case .yearly:
            NSLocalizedString(
                "statsGranularityV4.yearly",
                value: "By year",
                comment: "Display text for the yearly granularity of store stats on the My Store screen"
            )
        }
    }
}
