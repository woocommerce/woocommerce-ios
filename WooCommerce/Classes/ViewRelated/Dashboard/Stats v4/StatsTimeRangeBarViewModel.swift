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
            let format = NSLocalizedString("%1$@ – %2$@", comment: "Displays a date range for a stats interval")
            return String.localizedStringWithFormat(format, startDateString, endDateString)
        case let .custom(customStartDate, customEndDate):
            let differenceInDay = StatsTimeRangeV4.differenceInDays(startDate: customStartDate, endDate: customEndDate)
            if differenceInDay == .sameDay {
                // Return only the day if it's the same day.
                return dateFormatter.string(from: startDate)
            }
            // Always display the exact dates for custom range otherwise.
            let startDateString = dateFormatter.string(from: customStartDate)
            let endDateString = dateFormatter.string(from: customEndDate)
            let format = NSLocalizedString("%1$@ – %2$@", comment: "Displays a date range for a custom stats interval")
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
    let selectedDateText: String?
    let isTimeRangeEditable: Bool

    init(startDate: Date,
         endDate: Date,
         timeRange: StatsTimeRangeV4,
         timezone: TimeZone) {
        isTimeRangeEditable = timeRange.isCustomTimeRange
        timeRangeText = timeRange.timeRangeText(startDate: startDate,
                                                endDate: endDate,
                                                timezone: timezone)
        selectedDateText = nil
    }

    init(startDate: Date,
         endDate: Date,
         selectedDate: Date,
         timeRange: StatsTimeRangeV4,
         timezone: TimeZone) {
        isTimeRangeEditable = timeRange.isCustomTimeRange
        if timeRange.isCustomTimeRange {
            timeRangeText = timeRange.timeRangeText(startDate: startDate,
                                                    endDate: endDate,
                                                    timezone: timezone)
            selectedDateText = timeRange.timeRangeText(startDate: startDate,
                                                       endDate: endDate,
                                                       selectedDate: selectedDate,
                                                       timezone: timezone)
        } else {
            /// Shows the selected date in place of the time range label for non-custom range tabs.
            timeRangeText = timeRange.timeRangeText(startDate: startDate,
                                                    endDate: endDate,
                                                    selectedDate: selectedDate,
                                                    timezone: timezone)
            selectedDateText = nil
        }
    }

    init?(timeRange: StatsTimeRangeV4,
          timezone: TimeZone) {
        let now = Date()
        let startDate: Date? = {
            switch timeRange {
            case .today:
                now.startOfDay(timezone: timezone)
            case .thisWeek:
                now.startOfWeek(timezone: timezone)
            case .thisMonth:
                now.startOfMonth(timezone: timezone)
            case .thisYear:
                now.startOfYear(timezone: timezone)
            case let .custom(start, _):
                start
            }
        }()

        let endDate: Date? = {
            switch timeRange {
            case .today:
                now.endOfDay(timezone: timezone)
            case .thisWeek:
                now.endOfWeek(timezone: timezone)
            case .thisMonth:
                now.endOfMonth(timezone: timezone)
            case .thisYear:
                now.endOfYear(timezone: timezone)
            case let .custom(_, end):
                end
            }
        }()

        guard let startDate, let endDate else {
            return nil
        }

        self.init(startDate: startDate,
                  endDate: endDate,
                  timeRange: timeRange,
                  timezone: timezone)
    }
}
