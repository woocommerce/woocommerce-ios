import Foundation
import Yosemite

struct AnalyticsHubTimeRange {
    let start: Date
    let end: Date
}

/// Main source of time ranges of the Analytics Hub, responsible for generating the current and previous dates
/// for a given Date and range Type alongside their UI descriptions
///
public class AnalyticsHubTimeRangeGenerator {

    private let currentTimezone = TimeZone.autoupdatingCurrent
    private let currentDate: Date
    private let currentCalendar: Calendar
    let selectionType: AnalyticsHubViewModel.TimeRangeSelectionType

    private var currentTimeRange: AnalyticsHubTimeRange? = nil
    private var previousTimeRange: AnalyticsHubTimeRange? = nil

    //TODO: abandon usage of the ISO 8601 Calendar and build one based on the Site calendar configuration
    init(selectionType: AnalyticsHubViewModel.TimeRangeSelectionType,
         currentDate: Date = Date(),
         currentCalendar: Calendar = Calendar(identifier: .iso8601)) {
        self.currentDate = currentDate
        self.currentCalendar = currentCalendar
        self.selectionType = selectionType
        self.currentTimeRange = generateCurrentTimeRange()
        self.previousTimeRange = generatePreviousTimeRange()
    }

    /// Unwrap the generated selected `AnalyticsHubTimeRange` based on the `selectedTimeRange`
    /// provided during initialization.
    /// - throws an `.selectedRangeGenerationFailed` error if the unwrap fails.
    func unwrapCurrentTimeRange() throws -> AnalyticsHubTimeRange {
        guard let currentTimeRange = currentTimeRange else {
            throw TimeRangeGeneratorError.selectedRangeGenerationFailed
        }
        return currentTimeRange
    }

    /// Unwrap the generated previous `AnalyticsHubTimeRange`relative to the selected one
    /// based on the `selectedTimeRange` provided during initialization.
    /// - throws a `.previousRangeGenerationFailed` error if the unwrap fails.
    func unwrapPreviousTimeRange() throws -> AnalyticsHubTimeRange {
        guard let previousTimeRange = previousTimeRange else {
            throw TimeRangeGeneratorError.previousRangeGenerationFailed
        }
        return previousTimeRange
    }

    /// Generates a date description of the previous time range set internally.
    /// - Returns the Time range in a UI friendly format. If the previous time range is not available,
    /// then returns an presentable error message.
    func generateCurrentRangeDescription() -> String {
        guard let currentTimeRange = currentTimeRange else {
            return Localization.noCurrentPeriodAvailable
        }
        return generateDescriptionOf(timeRange: currentTimeRange)
    }

    /// Generates a date description of the previous time range set internally.
    /// - Returns the Time range in a UI friendly format. If the previous time range is not available,
    /// then returns an presentable error message.
    func generatePreviousRangeDescription() -> String {
        guard let previousTimeRange = previousTimeRange else {
            return Localization.noPreviousPeriodAvailable
        }
        return generateDescriptionOf(timeRange: previousTimeRange)
    }

    private func generateCurrentTimeRange() -> AnalyticsHubTimeRange? {
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

    private func generatePreviousTimeRange() -> AnalyticsHubTimeRange? {
        switch selectionType {
        case .today:
            guard let oneDayAgo = currentCalendar.date(byAdding: .day, value: -1, to: currentDate) else {
                return nil
            }

            return AnalyticsHubTimeRange(start: oneDayAgo.startOfDay(timezone: currentTimezone), end: oneDayAgo)

        case .weekToDate:
            guard let oneWeekAgo = currentCalendar.date(byAdding: .day, value: -7, to: currentDate),
                  let lastWeekStart = oneWeekAgo.startOfWeek(timezone: currentTimezone, calendar: currentCalendar) else {
                return nil
            }

            return AnalyticsHubTimeRange(start: lastWeekStart, end: oneWeekAgo)

        case .monthToDate:
            guard let oneMonthAgo = currentCalendar.date(byAdding: .month, value: -1, to: currentDate),
                  let lastMonthStart = oneMonthAgo.startOfMonth(timezone: currentTimezone) else {
                return nil
            }

            return AnalyticsHubTimeRange(start: lastMonthStart, end: oneMonthAgo)

        case .yearToDate:
            guard let oneYearAgo = currentCalendar.date(byAdding: .year, value: -1, to: currentDate),
                  let lastYearStart = oneYearAgo.startOfYear(timezone: currentTimezone) else {
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

// MARK: - Constants
extension AnalyticsHubTimeRangeGenerator {

    enum TimeRangeGeneratorError: Error {
        case selectedRangeGenerationFailed
        case previousRangeGenerationFailed
    }

    enum Localization {
        static let noCurrentPeriodAvailable = NSLocalizedString("No current period available",
                                                                comment: "A error message when it's not possible to acquire"
                                                                + "the Analytics Hub current selection range")
        static let noPreviousPeriodAvailable = NSLocalizedString("no previous period",
                                                                 comment: "A error message when it's not possible to"
                                                                 + "acquire the Analytics Hub previous selection range")
    }
}
