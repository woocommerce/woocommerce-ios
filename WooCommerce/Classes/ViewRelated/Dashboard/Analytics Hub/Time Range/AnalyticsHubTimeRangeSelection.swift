import Foundation
import Yosemite

protocol AnalyticsHubTimeRangeSelectionDelegate {
    var currentTimeRange: AnalyticsHubTimeRange? { get }
    var previousTimeRange: AnalyticsHubTimeRange? { get }
    var currentRangeDescription: String? { get }
    var previousRangeDescription: String? { get }

    init(referenceDate: Date, currentCalendar: Calendar)
}

/// Main source of time ranges of the Analytics Hub, responsible for providing the current and previous dates
/// for a given Date and range Type alongside their UI descriptions
///
public class AnalyticsHubTimeRangeSelection {
    private let timeRangeSelection: AnalyticsHubTimeRangeSelectionDelegate
    let rangeSelectionDescription: String

    //TODO: abandon usage of the ISO 8601 Calendar and build one based on the Site calendar configuration
    init(selectionType: AnalyticsHubViewModel.TimeRangeSelectionType,
         currentDate: Date = Date(),
         currentCalendar: Calendar = Calendar(identifier: .iso8601)) {
        self.rangeSelectionDescription = selectionType.description

        switch selectionType {
        case .today:
            self.timeRangeSelection = AnalyticsHubDayRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .weekToDate:
            self.timeRangeSelection = AnalyticsHubWeekRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .monthToDate:
            self.timeRangeSelection = AnalyticsHubMonthRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .yearToDate:
            self.timeRangeSelection = AnalyticsHubYearRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        }
    }

    /// Unwrap the generated selected `AnalyticsHubTimeRange` based on the `selectedTimeRange`
    /// provided during initialization.
    /// - throws an `.selectedRangeGenerationFailed` error if the unwrap fails.
    func unwrapCurrentTimeRange() throws -> AnalyticsHubTimeRange {
        guard let currentTimeRange = timeRangeSelection.currentTimeRange else {
            throw TimeRangeGeneratorError.selectedRangeGenerationFailed
        }
        return currentTimeRange
    }

    /// Unwrap the generated previous `AnalyticsHubTimeRange`relative to the selected one
    /// based on the `selectedTimeRange` provided during initialization.
    /// - throws a `.previousRangeGenerationFailed` error if the unwrap fails.
    func unwrapPreviousTimeRange() throws -> AnalyticsHubTimeRange {
        guard let previousTimeRange = timeRangeSelection.previousTimeRange else {
            throw TimeRangeGeneratorError.previousRangeGenerationFailed
        }
        return previousTimeRange
    }

    /// Generates a date description of the previous time range set internally.
    /// - Returns the Time range in a UI friendly format. If the previous time range is not available,
    /// then returns an presentable error message.
    func generateCurrentRangeDescription() -> String {
        guard let currentTimeRangeDescription = timeRangeSelection.currentRangeDescription else {
            return Localization.noCurrentPeriodAvailable
        }
        return currentTimeRangeDescription
    }

    /// Generates a date description of the previous time range set internally.
    /// - Returns the Time range in a UI friendly format. If the previous time range is not available,
    /// then returns an presentable error message.
    func generatePreviousRangeDescription() -> String {
        guard let previousTimeRangeDescription = timeRangeSelection.previousRangeDescription else {
            return Localization.noPreviousPeriodAvailable
        }
        return previousTimeRangeDescription
    }
}

// MARK: - Constants
extension AnalyticsHubTimeRangeSelection {

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
