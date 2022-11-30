import Foundation
import Yosemite

protocol AnalyticsHubTimeRangeSelection {
    var currentTimeRange: AnalyticsHubTimeRange? { get }
    var previousTimeRange: AnalyticsHubTimeRange? { get }

    init(referenceDate: Date, currentCalendar: Calendar)
}

/// Main source of time ranges of the Analytics Hub, responsible for providing the current and previous dates
/// for a given Date and range Type alongside their UI descriptions
///
public class AnalyticsHubTimeRangeSelectionData {

    private let currentTimezone = TimeZone.autoupdatingCurrent
    private let currentDate: Date
    private let currentCalendar: Calendar
    private let selectionType: AnalyticsHubViewModel.TimeRangeSelectionType

    private var currentTimeRange: AnalyticsHubTimeRange? = nil
    private var previousTimeRange: AnalyticsHubTimeRange? = nil

    var rangeSelectionDescription: String {
        selectionType.description
    }

    //TODO: abandon usage of the ISO 8601 Calendar and build one based on the Site calendar configuration
    init(selectionType: AnalyticsHubViewModel.TimeRangeSelectionType,
         currentDate: Date = Date(),
         currentCalendar: Calendar = Calendar(identifier: .iso8601)) {
        self.currentDate = currentDate
        self.currentCalendar = currentCalendar
        self.selectionType = selectionType

        let timeRangeSelection = generateTimeRangeSelection()
        self.currentTimeRange = timeRangeSelection.currentTimeRange
        self.previousTimeRange = timeRangeSelection.previousTimeRange
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

    private func generateTimeRangeSelection() -> AnalyticsHubTimeRangeSelection {
        switch selectionType {
        case .today:
            return AnalyticsHubDayRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .weekToDate:
            return AnalyticsHubWeekRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .monthToDate:
            return AnalyticsHubMonthRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .yearToDate:
            return AnalyticsHubYearRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        }
    }

    private func generateDescriptionOf(timeRange: AnalyticsHubTimeRange) -> String {
        if selectionType == .today {
            return DateFormatter.Stats.analyticsHubDayMonthYearFormatter.string(from: timeRange.start)
        } else {
            return timeRange.generateDescription(referenceCalendar: currentCalendar)
        }
    }
}

// MARK: - Constants
extension AnalyticsHubTimeRangeSelectionData {

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
