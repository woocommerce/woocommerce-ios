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
            return TimeRange(start: Date(), end: Date())
        case .yearToDate:
            return TimeRange(start: Date(), end: Date())
        }
    }
}

extension Date {
    func asFirstDayOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }

    func startOfLastMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: -1, to: asFirstDayOfMonth())!
    }

    func asFirstDayOfYear() -> Date {
        let year = Calendar.current.component(.year, from: Date())
        return Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
    }

    func startOfLastYear() -> Date {
        let year = Calendar.current.component(.year, from: Date())
        return Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
    }
}
