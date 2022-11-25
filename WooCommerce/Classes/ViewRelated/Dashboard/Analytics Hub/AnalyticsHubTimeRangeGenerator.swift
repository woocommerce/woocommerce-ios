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

    lazy private(set) var currentTimeRange: AnalyticsHubTimeRange = {
        generateCurrentTimeRangeFrom(selectionType: selectionType)
    }()

    var previousTimeRange: AnalyticsHubTimeRange {
        get throws {
            return try generatePreviousTimeRangeFrom(selectionType: selectionType)
        }
    }

    lazy private(set) var currentRangeDescription: String = {
        generateDescriptionOf(timeRange: currentTimeRange)
    }()

    var previousRangeDescription: String {
        get {
            do {
                return try generateDescriptionOf(timeRange: previousTimeRange)
            } catch {
                return Localization.noPreviousPeriodAvailable
            }
        }
    }

    var selectionDescription: String {
        selectionType.description
    }

    init(selectedTimeRange: StatsTimeRangeV4,
         currentDate: Date = Date(),
         currentCalendar: Calendar = Calendar(identifier: .iso8601)) {
        self.selectionType = SelectionType.from(selectedTimeRange)
        self.currentDate = currentDate
        self.currentCalendar = currentCalendar
    }

    private func generateCurrentTimeRangeFrom(selectionType: SelectionType) -> AnalyticsHubTimeRange {
        switch selectionType {
        case .today:
            return AnalyticsHubTimeRange(start: currentDate.startOfDay(timezone: currentTimezone), end: currentDate)
        case .weekToDate:
            let weekStart = currentDate.startOfWeek(timezone: currentTimezone, calendar: currentCalendar)
            return AnalyticsHubTimeRange(start: weekStart, end: currentDate)
        case .monthToDate:
            return AnalyticsHubTimeRange(start: currentDate.startOfMonth(timezone: currentTimezone), end: currentDate)
        case .yearToDate:
            return AnalyticsHubTimeRange(start: currentDate.startOfYear(timezone: currentTimezone), end: currentDate)
        }
    }

    private func generatePreviousTimeRangeFrom(selectionType: SelectionType) throws -> AnalyticsHubTimeRange {
        switch selectionType {
        case .today:
            guard let oneDayAgo = currentCalendar.date(byAdding: .day, value: -1, to: currentDate) else {
                throw TimeRangeGeneratorError.previousRangeGenerationFailed
            }
            return AnalyticsHubTimeRange(start: oneDayAgo.startOfDay(timezone: currentTimezone), end: oneDayAgo)

        case .weekToDate:
            guard let oneWeekAgo = currentCalendar.date(byAdding: .day, value: -7, to: currentDate) else {
                throw TimeRangeGeneratorError.previousRangeGenerationFailed
            }
            let lastWeekStart = oneWeekAgo.startOfWeek(timezone: currentTimezone, calendar: currentCalendar)
            return AnalyticsHubTimeRange(start: lastWeekStart, end: oneWeekAgo)

        case .monthToDate:
            guard let oneMonthAgo = currentCalendar.date(byAdding: .month, value: -1, to: currentDate) else {
                throw TimeRangeGeneratorError.previousRangeGenerationFailed
            }
            return AnalyticsHubTimeRange(start: oneMonthAgo.startOfMonth(timezone: currentTimezone), end: oneMonthAgo)

        case .yearToDate:
            guard let oneYearAgo = currentCalendar.date(byAdding: .year, value: -1, to: currentDate) else {
                throw TimeRangeGeneratorError.previousRangeGenerationFailed
            }
            return AnalyticsHubTimeRange(start: oneYearAgo.startOfYear(timezone: currentTimezone), end: oneYearAgo)
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
        static let noPreviousPeriodAvailable = NSLocalizedString("no previous period", comment: "")
    }
}
