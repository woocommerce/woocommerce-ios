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

    init(selectionType: SelectionType,
         currentDate: Date = Date(),
         timezone: TimeZone = TimeZone.current,
         calendar: Calendar = Locale.current.calendar) {

        // Exit early if we can't generate a selection Data.
        guard let selectionData = selectionType.toRangeData(referenceDate: currentDate, timezone: timezone, calendar: calendar) else {
            self.currentTimeRange = nil
            self.previousTimeRange = nil
            self.formattedCurrentRangeText = nil
            self.formattedPreviousRangeText = nil
            self.rangeSelectionDescription = ""
            return
        }

        self.currentTimeRange = selectionData.currentTimeRange
        self.previousTimeRange = selectionData.previousTimeRange
        self.rangeSelectionDescription = selectionType.description
        self.formattedCurrentRangeText = selectionData.formattedCurrentRange
        self.formattedPreviousRangeText = selectionData.formattedPreviousRange
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
    enum SelectionType: Equatable {

        case custom(start: Date, end: Date)
        case today
        case yesterday
        case lastWeek
        case lastMonth
        case lastQuarter
        case lastYear
        case weekToDate
        case monthToDate
        case quarterToDate
        case yearToDate

        /// The granularity that should be used to request stats from the given SelectedType
        ///
        var granularity: StatsGranularityV4 {
            switch self {
            case .today, .yesterday:
                return .hourly
            case .custom, .weekToDate, .lastWeek:
                return .daily
            case .monthToDate, .lastMonth:
                return .daily
            case .quarterToDate, .lastQuarter:
                return .weekly
            case .yearToDate, .lastYear:
                return .monthly
            }
        }

        /// The response interval size that should be used to request stats from the given SelectedType
        /// in order to proper determine the stats charts and changes
        ///
        var intervalSize: Int {
            switch self {
            case .custom, .today, .yesterday:
                return 24
            case .weekToDate, .lastWeek:
                return 7
            case .monthToDate, .lastMonth:
                return 31
            case .quarterToDate, .lastQuarter:
                return 13
            case .yearToDate, .lastYear:
                return 12
            }
        }

        /// The period used to request site summary stats from the given SelectedType.
        ///
        /// Returns `nil` if there isn't a `StatGranularity` period that can be used to fetch stats for the given SelectedType.
        ///
        var period: StatGranularity? {
            switch self {
            case .custom:
                return nil
            case .today, .yesterday:
                return .day
            case .weekToDate, .lastWeek:
                return .week
            case .monthToDate, .lastMonth, .quarterToDate, .lastQuarter:
                return .month
            case .yearToDate, .lastYear:
                return .year
            }
        }

        /// The quantity of periods used to request site summary stats from the given SelectedType.
        ///
        /// Defaults to 1 (a single period) except for ranges not matching a `StatGranularity` period.
        ///
        var quantity: Int {
            switch self {
            case .quarterToDate, .lastQuarter:
                return 3 // Stats summary calculated from 3 months of data
            default:
                return 1
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

// MARK: - SelectionType helper functions
private extension AnalyticsHubTimeRangeSelection.SelectionType {
    func toRangeData(referenceDate: Date, timezone: TimeZone, calendar: Calendar) -> AnalyticsHubTimeRangeData? {
        switch self {
        case let .custom(start, end):
            return AnalyticsHubCustomRangeData(start: start, end: end, timezone: timezone, calendar: calendar)
        case .today:
            return AnalyticsHubTodayRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .yesterday:
            return AnalyticsHubYesterdayRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .lastWeek:
            return AnalyticsHubLastWeekRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .lastMonth:
            return AnalyticsHubLastMonthRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .lastQuarter:
            return AnalyticsHubLastQuarterRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .lastYear:
            return AnalyticsHubLastYearRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .weekToDate:
            return AnalyticsHubWeekToDateRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .monthToDate:
            return AnalyticsHubMonthToDateRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
        case .quarterToDate:
            return AnalyticsHubQuarterToDateRangeData(referenceDate: referenceDate, timezone: timezone, calendar: calendar)
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
