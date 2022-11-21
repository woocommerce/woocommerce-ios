import Foundation

struct TimeRange {
    let start: Date
    let end: Date

    var description: String {
        get {
            return "Range description"
        }
    }
}

public enum SelectionType: String {
    case today = "Today"
    case weekToDate = "Week to Date"
    case monthToDate = "Month to Date"
    case yearToDate = "Year to Date"
}

public class AnalyticsHubTimeRange {

    private let currentTimezone: TimeZone
    let selectionType: SelectionType

    lazy private(set) var selectedTimeRange: TimeRange = {
        return generateSelectedTimeRangeFrom(selectionType: selectionType)
    }()

    lazy private(set) var previousTimeRange: TimeRange = {
        return generatePreviousTimeRangeFrom(selectionType: selectionType)
    }()


    init(selectionType: SelectionType, siteTimezone: TimeZone = TimeZone.current) {
        self.selectionType = selectionType
        self.currentTimezone = siteTimezone
    }

    private func generateSelectedTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        let now = Date()
        switch selectionType {
        case .today:
            return TimeRange(start: now.startOfDay(timezone: currentTimezone), end: now)
        case .weekToDate:
            return TimeRange(start: now.startOfWeek(timezone: currentTimezone), end: now)
        case .monthToDate:
            return TimeRange(start: now.startOfMonth(timezone: currentTimezone), end: now)
        case .yearToDate:
            return TimeRange(start: now.startOfYear(timezone: currentTimezone), end: now)
        }
    }

    private func generatePreviousTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        let now = Date()
        switch selectionType {
        case .today:
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            return TimeRange(start: oneDayAgo.startOfDay(timezone: currentTimezone), end: oneDayAgo)
        case .weekToDate:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            return TimeRange(start: oneWeekAgo.startOfWeek(timezone: currentTimezone), end: oneWeekAgo)
        case .monthToDate:
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
            return TimeRange(start: oneMonthAgo.startOfMonth(timezone: currentTimezone), end: oneMonthAgo)
        case .yearToDate:
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            return TimeRange(start: oneYearAgo.startOfYear(timezone: currentTimezone), end: oneYearAgo)
        }
    }
}
