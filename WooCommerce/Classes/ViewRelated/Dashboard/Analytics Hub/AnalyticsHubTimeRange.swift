import Foundation

enum SelectionType {
    case today
    case weekToDate
    case monthToDate
    case yearToDate
}

struct TimeRange {
    let start: Date
    let end: Date
}

public class AnalyticsHubTimeRange {

    private let siteTimezone: TimeZone
    private let selectionType: SelectionType

    lazy private(set) var selectedTimeRange: TimeRange = {
        return generateSelectedTimeRangeFrom(selectionType: selectionType)
    }()

    lazy private(set) var previousTimeRange: TimeRange = {
        return generatePreviousTimeRangeFrom(selectionType: selectionType)
    }()


    init(selectionType: SelectionType, siteTimezone: TimeZone = TimeZone.siteTimezone) {
        self.selectionType = selectionType
        self.siteTimezone = siteTimezone
    }

    private func generateSelectedTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        let now = Date()
        switch selectionType {
        case .today:
            return TimeRange(start: now.startOfDay(timezone: siteTimezone), end: now)
        case .weekToDate:
            return TimeRange(start: now.startOfWeek(timezone: siteTimezone), end: now)
        case .monthToDate:
            return TimeRange(start: now.startOfMonth(timezone: siteTimezone), end: now)
        case .yearToDate:
            return TimeRange(start: now.startOfYear(timezone: siteTimezone), end: now)
        }
    }

    private func generatePreviousTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        let now = Date()
        switch selectionType {
        case .today:
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            return TimeRange(start: oneDayAgo.startOfDay(timezone: siteTimezone), end: oneDayAgo)
        case .weekToDate:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            return TimeRange(start: oneWeekAgo.startOfWeek(timezone: siteTimezone), end: oneWeekAgo)
        case .monthToDate:
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
            return TimeRange(start: oneMonthAgo.startOfMonth(timezone: siteTimezone), end: oneMonthAgo)
        case .yearToDate:
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            return TimeRange(start: oneYearAgo.startOfYear(timezone: siteTimezone), end: oneYearAgo)
        }
    }
}
