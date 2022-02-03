import Experiments
import Yosemite

private extension StatsTimeRangeV4 {
    func timeRangeText(startDate: Date, endDate: Date, selectedDate: Date, timezone: TimeZone, isMyStoreTabUpdatesEnabled: Bool) -> String {
        let selectedDateString = timeRangeSelectedDateFormatter(timezone: timezone,
                                                                isMyStoreTabUpdatesEnabled: isMyStoreTabUpdatesEnabled)
            .string(from: selectedDate)

        if isMyStoreTabUpdatesEnabled {
            return selectedDateString
        } else {
            switch self {
            case .today, .thisYear:
                let dateBreadcrumbFormat = NSLocalizedString("%1$@ › %2$@", comment: "Displays a time range followed by a specific date/time")
                let timeRangeString = timeRangeText(startDate: startDate,
                                                    endDate: endDate,
                                                    timezone: timezone,
                                                    isMyStoreTabUpdatesEnabled: isMyStoreTabUpdatesEnabled)
                return String.localizedStringWithFormat(dateBreadcrumbFormat, timeRangeString, selectedDateString)
            case .thisWeek, .thisMonth:
                return selectedDateString
            }
        }
    }

    func timeRangeText(startDate: Date, endDate: Date, timezone: TimeZone, isMyStoreTabUpdatesEnabled: Bool) -> String {
        let dateFormatter = timeRangeDateFormatter(timezone: timezone, isMyStoreTabUpdatesEnabled: isMyStoreTabUpdatesEnabled)
        switch self {
        case .today, .thisMonth, .thisYear:
            return dateFormatter.string(from: startDate)
        case .thisWeek:
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            let format = isMyStoreTabUpdatesEnabled ?
            NSLocalizedString("%1$@ - %2$@", comment: "Displays a date range for a stats interval"):
            NSLocalizedString("%1$@-%2$@", comment: "Displays a date range for a stats interval in the legacy version")
            return String.localizedStringWithFormat(format, startDateString, endDateString)
        }
    }

    func timeRangeDateFormatter(timezone: TimeZone, isMyStoreTabUpdatesEnabled: Bool) -> DateFormatter {
        let dateFormatter: DateFormatter
        switch self {
        case .today:
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
            dateFormatter = formatter
        case .thisWeek:
            dateFormatter = DateFormatter.Charts.chartAxisDayFormatter
        case .thisMonth:
            dateFormatter = isMyStoreTabUpdatesEnabled ?
            DateFormatter.Charts.chartAxisFullMonthFormatter:
            DateFormatter.Charts.legacyChartAxisFullMonthFormatter
        case .thisYear:
            dateFormatter = DateFormatter.Charts.chartAxisYearFormatter
        }
        dateFormatter.timeZone = timezone
        return dateFormatter
    }

    /// Date formatter for a selected date for a time range.
    func timeRangeSelectedDateFormatter(timezone: TimeZone, isMyStoreTabUpdatesEnabled: Bool) -> DateFormatter {
        let dateFormatter: DateFormatter
        switch self {
        case .today:
            dateFormatter = isMyStoreTabUpdatesEnabled ?
            DateFormatter.Charts.chartSelectedDateHourFormatter:
            DateFormatter.Charts.legacyChartSelectedDateHourFormatter
        case .thisWeek, .thisMonth:
            dateFormatter = DateFormatter.Charts.chartAxisDayFormatter
        case .thisYear:
            dateFormatter = isMyStoreTabUpdatesEnabled ? DateFormatter.Charts.chartAxisFullMonthFormatter:
            DateFormatter.Charts.legacyChartAxisFullMonthFormatter
        }
        dateFormatter.timeZone = timezone
        return dateFormatter
    }
}

/// View model for `StatsTimeRangeBarView`.
struct StatsTimeRangeBarViewModel: Equatable {
    let timeRangeText: String

    init(startDate: Date,
         endDate: Date,
         timeRange: StatsTimeRangeV4,
         timezone: TimeZone,
         isMyStoreTabUpdatesEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.myStoreTabUpdates)) {
        timeRangeText = timeRange.timeRangeText(startDate: startDate,
                                                endDate: endDate,
                                                timezone: timezone,
                                                isMyStoreTabUpdatesEnabled: isMyStoreTabUpdatesEnabled)
    }

    init(startDate: Date,
         endDate: Date,
         selectedDate: Date,
         timeRange: StatsTimeRangeV4,
         timezone: TimeZone,
         isMyStoreTabUpdatesEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.myStoreTabUpdates)) {
        timeRangeText = timeRange.timeRangeText(startDate: startDate,
                                                endDate: endDate,
                                                selectedDate: selectedDate,
                                                timezone: timezone,
                                                isMyStoreTabUpdatesEnabled: isMyStoreTabUpdatesEnabled)
    }
}
