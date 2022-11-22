import Foundation
import Yosemite

struct TimeRange {
    let start: Date
    let end: Date
}

public enum SelectionType: String {
    case today = "Today"
    case weekToDate = "Week to Date"
    case monthToDate = "Month to Date"
    case yearToDate = "Year to Date"
}

public class AnalyticsHubTimeRange {

    private let currentTimezone = TimeZone.current
    private let currentDate: Date
    private let currentCalendar: Calendar
    let selectionType: SelectionType

    lazy private(set) var currentTimeRange: TimeRange = {
        generateCurrentTimeRangeFrom(selectionType: selectionType)
    }()

    lazy private(set) var previousTimeRange: TimeRange = {
        generatePreviousTimeRangeFrom(selectionType: selectionType)
    }()

    lazy private(set) var currentRangeDescription: String = {
        generateDescriptionOf(timeRange: currentTimeRange)
    }()

    lazy private(set) var previousRangeDescription: String = {
        generateDescriptionOf(timeRange: previousTimeRange)
    }()

    init(selectedTimeRange: StatsTimeRangeV4,
         currentDate: Date = Date(),
         currentCalendar: Calendar = Calendar(identifier: .iso8601)
    ) {
        self.selectionType = selectedTimeRange.toAnalyticsHubSelectionType()
        self.currentDate = currentDate
        self.currentCalendar = currentCalendar
    }

    private func generateCurrentTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        switch selectionType {
        case .today:
            return TimeRange(start: currentDate.startOfDay(timezone: currentTimezone), end: currentDate)
        case .weekToDate:
            let weekStart = currentDate.startOfWeek(timezone: currentTimezone, calendar: currentCalendar)
            return TimeRange(start: weekStart, end: currentDate)
        case .monthToDate:
            return TimeRange(start: currentDate.startOfMonth(timezone: currentTimezone), end: currentDate)
        case .yearToDate:
            return TimeRange(start: currentDate.startOfYear(timezone: currentTimezone), end: currentDate)
        }
    }

    private func generatePreviousTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        switch selectionType {
        case .today:
            let oneDayAgo = currentCalendar.date(byAdding: .day, value: -1, to: currentDate)!
            return TimeRange(start: oneDayAgo.startOfDay(timezone: currentTimezone), end: oneDayAgo)
        case .weekToDate:
            let oneWeekAgo = currentCalendar.date(byAdding: .day, value: -7, to: currentDate)!
            let lastWeekStart = oneWeekAgo.startOfWeek(timezone: currentTimezone, calendar: currentCalendar)
            return TimeRange(start: lastWeekStart, end: oneWeekAgo)
        case .monthToDate:
            let oneMonthAgo = currentCalendar.date(byAdding: .month, value: -1, to: currentDate)!
            return TimeRange(start: oneMonthAgo.startOfMonth(timezone: currentTimezone), end: oneMonthAgo)
        case .yearToDate:
            let oneYearAgo = currentCalendar.date(byAdding: .year, value: -1, to: currentDate)!
            return TimeRange(start: oneYearAgo.startOfYear(timezone: currentTimezone), end: oneYearAgo)
        }
    }

    private func generateDescriptionOf(timeRange: TimeRange) -> String {
        let dateFormatter = DateFormatter()

        if selectionType == .today {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: timeRange.start)
        }

        dateFormatter.dateFormat = "MMM d"
        let startDateDescription = dateFormatter.string(from: timeRange.start)
        let endDateDescription = generateEndDateDescription(endDate: timeRange.end, dateFormatter: dateFormatter)

        return "\(startDateDescription) - \(endDateDescription)"
    }

    private func generateEndDateDescription(endDate: Date, dateFormatter: DateFormatter) -> String {
        if selectionType == .yearToDate {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: endDate)
        } else {
            dateFormatter.dateFormat = "d, yyyy"
            return dateFormatter.string(from: endDate)
        }
    }
}

private extension StatsTimeRangeV4 {
    func toAnalyticsHubSelectionType() -> SelectionType {
        switch self {
        case .today:
            return .today
        case .thisWeek:
            return .weekToDate
        case .thisMonth:
            return .monthToDate
        case .thisYear:
            return .yearToDate
        }
    }
}
