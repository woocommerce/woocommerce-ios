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

    internal static let empty = TimeRange(start: Date(), end: Date())
}

public class AnalyticsHubTimeRange {

    private(set) var selectedTimeRange: TimeRange = TimeRange.empty
    private(set) var previousTimeRange: TimeRange = TimeRange.empty

    init(selectionType: SelectionType) {
        selectedTimeRange = generateSelectedTimeRangeFrom(selectionType: selectionType)
        previousTimeRange = generatePreviousTimeRangeFrom(selectionType: selectionType)
    }

    private func generateSelectedTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        let now = Date()
        switch selectionType {
        case .today:
            return TimeRange(start: Date(), end: now)
        case .weekToDate:
            return TimeRange(start: Date(), end: now)
        case .monthToDate:
            return TimeRange(start: now.asFirstDayOfMonth(), end: now)
        case .yearToDate:
            return TimeRange(start: now.asFirstDayOfYear(), end: now)
        }
    }

    private func generatePreviousTimeRangeFrom(selectionType: SelectionType) -> TimeRange {
        let now = Date()
        switch selectionType {
        case .today:
            return TimeRange(start: Date(), end: Date())
        case .weekToDate:
            return TimeRange(start: Date(), end: Date())
        case .monthToDate:
            let oneMonthAgo = now.oneMonthAgo()
            return TimeRange(start: oneMonthAgo.asFirstDayOfMonth(), end: oneMonthAgo)
        case .yearToDate:
            let oneYearAgo = now.oneYearAgo()
            return TimeRange(start: oneYearAgo.asFirstDayOfYear(), end: oneYearAgo)
        }
    }
}

private extension Date {
    func asFirstDayOfMonth() -> Date {
        let year = Calendar.current.component(.year, from: self)
        let month = Calendar.current.component(.month, from: self)
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!
    }

    func oneMonthAgo() -> Date {
        return Calendar.current.date(byAdding: .month, value: -1, to: self)!
    }

    func asFirstDayOfYear() -> Date {
        let year = Calendar.current.component(.year, from: self)
        return Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
    }

    func oneYearAgo() -> Date {
        return Calendar.current.date(byAdding: .year, value: -1, to: self)!
    }
}
