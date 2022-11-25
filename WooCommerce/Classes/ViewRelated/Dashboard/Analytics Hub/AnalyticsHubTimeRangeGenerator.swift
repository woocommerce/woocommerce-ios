import Foundation
import Yosemite

struct AnalyticsHubTimeRange {
    let start: Date
    let end: Date
}

public class AnalyticsHubTimeRangeGenerator {

    private let currentTimezone = TimeZone.autoupdatingCurrent
    private let currentDate: Date
    private let currentCalendar: Calendar
    private let selectionType: SelectionType
    
    private var _currentTimeRange: AnalyticsHubTimeRange? = nil
    private var _previousTimeRange: AnalyticsHubTimeRange? = nil

    var currentTimeRange: AnalyticsHubTimeRange {
        get throws {
            guard let currentTimeRange = _currentTimeRange else {
                throw TimeRangeGeneratorError.selectedRangeGenerationFailed
            }
            return currentTimeRange
        }
    }

    var previousTimeRange: AnalyticsHubTimeRange {
        get throws {
            guard let previousTimeRange = _previousTimeRange else {
                throw TimeRangeGeneratorError.previousRangeGenerationFailed
            }
            return previousTimeRange
        }
    }

    var currentRangeDescription: String {
        get {
            guard let currentTimeRange = _currentTimeRange else {
                return Localization.noCurrentPeriodAvailable
            }
            return generateDescriptionOf(timeRange: currentTimeRange)
        }
    }

    var previousRangeDescription: String {
        get {
            guard let previousTimeRange = _previousTimeRange else {
                return Localization.noPreviousPeriodAvailable
            }
            return generateDescriptionOf(timeRange: previousTimeRange)
        }
    }

    var selectionDescription: String {
        selectionType.description
    }

    init(selectedTimeRange: StatsTimeRangeV4,
         currentDate: Date = Date(),
         currentCalendar: Calendar = Calendar(identifier: .iso8601)) {
        self.currentDate = currentDate
        self.currentCalendar = currentCalendar
        self.selectionType = SelectionType.from(selectedTimeRange)
        _currentTimeRange = generateCurrentTimeRangeFrom(selectionType: selectionType)
        _previousTimeRange = generatePreviousTimeRangeFrom(selectionType: selectionType)
    }

    private func generateCurrentTimeRangeFrom(selectionType: SelectionType) -> AnalyticsHubTimeRange? {
        switch selectionType {
        case .today:
            return AnalyticsHubTimeRange(start: currentDate.startOfDay(timezone: currentTimezone), end: currentDate)

        case .weekToDate:
            guard let weekStart = currentDate.startOfWeek(timezone: currentTimezone, calendar: currentCalendar) else {
                return nil
            }
            return AnalyticsHubTimeRange(start: weekStart, end: currentDate)

        case .monthToDate:
            guard let monthStart = currentDate.startOfMonth(timezone: currentTimezone) else {
                return nil
            }
            return AnalyticsHubTimeRange(start: monthStart, end: currentDate)

        case .yearToDate:
            guard let yearStart = currentDate.startOfYear(timezone: currentTimezone) else {
                return nil
            }
            return AnalyticsHubTimeRange(start: yearStart, end: currentDate)
        }
    }

    private func generatePreviousTimeRangeFrom(selectionType: SelectionType) -> AnalyticsHubTimeRange? {
        switch selectionType {
        case .today:
            guard let oneDayAgo = currentCalendar.date(byAdding: .day, value: -1, to: currentDate) else {
                return nil
            }
            return AnalyticsHubTimeRange(start: oneDayAgo.startOfDay(timezone: currentTimezone), end: oneDayAgo)

        case .weekToDate:
            guard let oneWeekAgo = currentCalendar.date(byAdding: .day, value: -7, to: currentDate) else {
                return nil
            }
            guard let lastWeekStart = oneWeekAgo.startOfWeek(timezone: currentTimezone, calendar: currentCalendar) else {
                return nil
            }
            return AnalyticsHubTimeRange(start: lastWeekStart, end: oneWeekAgo)

        case .monthToDate:
            guard let oneMonthAgo = currentCalendar.date(byAdding: .month, value: -1, to: currentDate) else {
                return nil
            }
            guard let lastMonthStart = oneMonthAgo.startOfMonth(timezone: currentTimezone) else {
                return nil
            }

            return AnalyticsHubTimeRange(start: lastMonthStart, end: oneMonthAgo)

        case .yearToDate:
            guard let oneYearAgo = currentCalendar.date(byAdding: .year, value: -1, to: currentDate) else {
                return nil
            }
            guard let lastYearStart = oneYearAgo.startOfYear(timezone: currentTimezone) else {
                return nil
            }
            return AnalyticsHubTimeRange(start: lastYearStart, end: oneYearAgo)
        }
    }

    private func generateDescriptionOf(timeRange: AnalyticsHubTimeRange) -> String {
        if selectionType == .today {
            return DateFormatter.Stats.analyticsHubDayMonthYearFormatter.string(from: timeRange.start)
        }

        let startDateDescription = DateFormatter.Stats.analyticsHubDayMonthFormatter.string(from: timeRange.start)
        let endDateDescription = generateEndDateDescription(timeRange: timeRange)

        return "\(startDateDescription) - \(endDateDescription)"
    }

    private func generateEndDateDescription(timeRange: AnalyticsHubTimeRange) -> String {
        if timeRange.start.isSameMonth(as: timeRange.end, using: currentCalendar) {
            return DateFormatter.Stats.analyticsHubDayYearFormatter.string(from: timeRange.end)
        } else {
            return DateFormatter.Stats.analyticsHubDayMonthYearFormatter.string(from: timeRange.end)
        }
    }
}

private extension AnalyticsHubTimeRangeGenerator {

    enum TimeRangeGeneratorError: Error {
        case selectedRangeGenerationFailed
        case previousRangeGenerationFailed
    }

    enum SelectionType {
        case today
        case weekToDate
        case monthToDate
        case yearToDate

        var description: String {
            get {
                switch self {
                case .today:
                    return Localization.today
                case .weekToDate:
                    return Localization.weekToDate
                case .monthToDate:
                    return Localization.monthToDate
                case .yearToDate:
                    return Localization.yearToDate
                }
            }
        }

        static func from(_ statsTimeRange: StatsTimeRangeV4) -> SelectionType {
            switch statsTimeRange {
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

    enum Localization {
        static let today = NSLocalizedString("Today", comment: "Today")
        static let weekToDate = NSLocalizedString("Week to Date", comment: "Week to Date")
        static let monthToDate = NSLocalizedString("Month to Date", comment: "Month to Date")
        static let yearToDate = NSLocalizedString("Year to Date", comment: "Year to Date")
        static let noCurrentPeriodAvailable = NSLocalizedString("No current period available", comment: "")
        static let noPreviousPeriodAvailable = NSLocalizedString("No previous period available", comment: "")
    }
}
