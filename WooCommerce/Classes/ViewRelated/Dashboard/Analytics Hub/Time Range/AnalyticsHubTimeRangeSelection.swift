import Foundation

/// Main source of time ranges of the Analytics Hub, responsible for providing the current and previous dates
/// for a given Date and range Type alongside their UI descriptions
///
public class AnalyticsHubTimeRangeSelection {
    private let currentTimeRange: AnalyticsHubTimeRange?
    private let previousTimeRange: AnalyticsHubTimeRange?
    private let formattedCurrentRangeText: String?
    private let formattedPreviousRangeText: String?
    let rangeSelectionDescription: String

    /// Provide a date description of the current time range set internally.
    /// - Returns the Time range in a UI friendly format. If the current time range is not available,
    /// then returns an presentable error message.
    var currentRangeDescription: String {
        guard let currentTimeRangeDescription = formattedCurrentRangeText else {
            return Localization.noCurrentPeriodAvailable
        }
        return currentTimeRangeDescription
    }

    /// Generates a date description of the previous time range set internally.
    /// - Returns the Time range in a UI friendly format. If the previous time range is not available,
    /// then returns an presentable error message.
    var previousRangeDescription: String {
        guard let previousTimeRangeDescription = formattedPreviousRangeText else {
            return Localization.noPreviousPeriodAvailable
        }
        return previousTimeRangeDescription
    }

    //TODO: abandon usage of the ISO 8601 Calendar and build one based on the Site calendar configuration
    init(selectionType: AnalyticsHubTimeRangeSelectionType,
         currentDate: Date = Date(),
         timezone: TimeZone = TimeZone.autoupdatingCurrent,
         calendar: Calendar = Calendar(identifier: .iso8601)) {
        let selectionData = selectionType.mapToRangeData(referenceDate: currentDate, timezone: timezone, calendar: calendar)
        let currentTimeRange = selectionData.currentTimeRange
        let previousTimeRange = selectionData.previousTimeRange
        let simplifiedDescription = selectionType == .today || selectionType == .yesterday

        self.currentTimeRange = currentTimeRange
        self.previousTimeRange = previousTimeRange
        self.rangeSelectionDescription = selectionType.description
        self.formattedCurrentRangeText = currentTimeRange?.formatToString(simplified: simplifiedDescription,
                                                                          calendar: calendar)
        self.formattedPreviousRangeText = previousTimeRange?.formatToString(simplified: simplifiedDescription,
                                                                            calendar: calendar)
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
}

// MARK: - Data creation utility
private extension AnalyticsHubTimeRangeSelectionType {
    func mapToRangeData(referenceDate: Date, timezone: TimeZone, calendar: Calendar) -> AnalyticsHubTimeRangeData {
        switch self {
        case .today:
            return AnalyticsHubTodayRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .yesterday:
            return AnalyticsHubYesterdayRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .weekToDate:
            return AnalyticsHubWeekToDateRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .monthToDate:
            return AnalyticsHubMonthToDateRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .yearToDate:
            return AnalyticsHubYearToDateRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        }
    }
}

// MARK: - Constants
extension AnalyticsHubTimeRangeSelection {

    enum TimeRangeGeneratorError: Error {
        case selectedRangeGenerationFailed
        case previousRangeGenerationFailed
    }

    enum Localization {
        static let selectionTitle = NSLocalizedString("Date Range", comment: "Title of the range selection list")
        static let noCurrentPeriodAvailable = NSLocalizedString("No current period available",
                                                                comment: "A error message when it's not possible to acquire"
                                                                + "the Analytics Hub current selection range")
        static let noPreviousPeriodAvailable = NSLocalizedString("no previous period",
                                                                 comment: "A error message when it's not possible to"
                                                                 + "acquire the Analytics Hub previous selection range")
    }
}
