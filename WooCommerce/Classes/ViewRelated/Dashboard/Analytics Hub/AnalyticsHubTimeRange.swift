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

    private let currentTimezone: TimeZone
    private let currentDate: Date
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
         siteTimezone: TimeZone = TimeZone.current
    ) {
        self.selectionType = selectedTimeRange.toAnalyticsHubSelectionType()
        self.currentDate = currentDate
        self.currentTimezone = siteTimezone
    }

    private func generateCurrentTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        switch selectionType {
        case .today:
            return TimeRange(start: currentDate.startOfDay(timezone: currentTimezone), end: currentDate)
        case .weekToDate:
            return TimeRange(start: currentDate.startOfWeek(timezone: currentTimezone), end: currentDate)
        case .monthToDate:
            return TimeRange(start: currentDate.startOfMonth(timezone: currentTimezone), end: currentDate)
        case .yearToDate:
            return TimeRange(start: currentDate.startOfYear(timezone: currentTimezone), end: currentDate)
        }
    }

    private func generatePreviousTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        switch selectionType {
        case .today:
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            return TimeRange(start: oneDayAgo.startOfDay(timezone: currentTimezone), end: oneDayAgo)
        case .weekToDate:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: currentDate)!
            return TimeRange(start: oneWeekAgo.startOfWeek(timezone: currentTimezone), end: oneWeekAgo)
        case .monthToDate:
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!
            return TimeRange(start: oneMonthAgo.startOfMonth(timezone: currentTimezone), end: oneMonthAgo)
        case .yearToDate:
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: currentDate)!
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
