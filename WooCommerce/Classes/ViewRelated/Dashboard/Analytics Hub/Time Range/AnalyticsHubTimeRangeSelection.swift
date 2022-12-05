import Foundation
import Yosemite

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
    init(selectionType: SelectionType,
         currentDate: Date = Date(),
         timezone: TimeZone = TimeZone.autoupdatingCurrent,
         calendar: Calendar = Calendar(identifier: .iso8601)) {
        var selectionData: AnalyticsHubTimeRangeData

        switch selectionType {
        case .today:
            selectionData = AnalyticsHubDayRangeData(referenceDate: currentDate, timezone: timezone, calendar: calendar)
        case .weekToDate:
            selectionData = AnalyticsHubWeekRangeData(referenceDate: currentDate, timezone: timezone, calendar: calendar)
        case .monthToDate:
            selectionData = AnalyticsHubMonthRangeData(referenceDate: currentDate, timezone: timezone, calendar: calendar)
        case .yearToDate:
            selectionData = AnalyticsHubYearRangeData(referenceDate: currentDate, timezone: timezone, calendar: calendar)
        }

        let currentTimeRange = selectionData.currentTimeRange
        let previousTimeRange = selectionData.previousTimeRange
        self.currentTimeRange = currentTimeRange
        self.previousTimeRange = previousTimeRange

        let simplifiedDescription = selectionType == .today
        self.formattedCurrentRangeText = currentTimeRange?.formatToString(simplified: simplifiedDescription,
                                                                          timezone: timezone,
                                                                          calendar: calendar)
        self.formattedPreviousRangeText = previousTimeRange?.formatToString(simplified: simplifiedDescription,
                                                                            timezone: timezone,
                                                                            calendar: calendar)
        self.rangeSelectionDescription = selectionType.description
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

// MARK: - Time Range Selection Type
extension AnalyticsHubTimeRangeSelection {
    enum SelectionType: CaseIterable {
        case today
        case weekToDate
        case monthToDate
        case yearToDate

        var description: String {
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

        init(_ statsTimeRange: StatsTimeRangeV4) {
            switch statsTimeRange {
            case .today:
                self = .today
            case .thisWeek:
                self = .weekToDate
            case .thisMonth:
                self = .monthToDate
            case .thisYear:
                self = .yearToDate
            }
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
        static let today = NSLocalizedString("Today", comment: "Title of the Analytics Hub Today's selection range")
        static let weekToDate = NSLocalizedString("Week to Date", comment: "Title of the Analytics Hub Week to Date selection range")
        static let monthToDate = NSLocalizedString("Month to Date", comment: "Title of the Analytics Hub Month to Date selection range")
        static let yearToDate = NSLocalizedString("Year to Date", comment: "Title of the Analytics Hub Year to Date selection range")
        static let selectionTitle = NSLocalizedString("Date Range", comment: "Title of the range selection list")
        static let noCurrentPeriodAvailable = NSLocalizedString("No current period available",
                                                                comment: "A error message when it's not possible to acquire"
                                                                + "the Analytics Hub current selection range")
        static let noPreviousPeriodAvailable = NSLocalizedString("no previous period",
                                                                 comment: "A error message when it's not possible to"
                                                                 + "acquire the Analytics Hub previous selection range")
    }
}
