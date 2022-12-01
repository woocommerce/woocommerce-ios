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
    private let selectionDelegate: AnalyticsHubTimeRangeSelectionDelegate
    let rangeSelectionDescription: String

    //TODO: abandon usage of the ISO 8601 Calendar and build one based on the Site calendar configuration
    init(selectionType: SelectionType,
         currentDate: Date = Date(),
         currentCalendar: Calendar = Calendar(identifier: .iso8601)) {
        self.rangeSelectionDescription = selectionType.description

        switch selectionType {
        case .today:
            self.selectionDelegate = AnalyticsHubDayRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .yesterday:
            //TODO: use correct referenceDate parameter
            self.selectionDelegate = AnalyticsHubDayRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .lastWeek:
            //TODO: use correct referenceDate parameter
            self.selectionDelegate = AnalyticsHubWeekRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .lastMonth:
            //TODO: use correct referenceDate parameter
            self.selectionDelegate = AnalyticsHubWeekRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .weekToDate:
            self.selectionDelegate = AnalyticsHubWeekRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .monthToDate:
            self.selectionDelegate = AnalyticsHubMonthRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        case .yearToDate:
            self.selectionDelegate = AnalyticsHubYearRangeSelection(referenceDate: currentDate, currentCalendar: currentCalendar)
        }
    }

    /// Unwrap the generated selected `AnalyticsHubTimeRange` based on the `selectedTimeRange`
    /// provided during initialization.
    /// - throws an `.selectedRangeGenerationFailed` error if the unwrap fails.
    func unwrapCurrentTimeRange() throws -> AnalyticsHubTimeRange {
        guard let currentTimeRange = selectionDelegate.currentTimeRange else {
            throw TimeRangeGeneratorError.selectedRangeGenerationFailed
        }
        return currentTimeRange
    }

    /// Unwrap the generated previous `AnalyticsHubTimeRange`relative to the selected one
    /// based on the `selectedTimeRange` provided during initialization.
    /// - throws a `.previousRangeGenerationFailed` error if the unwrap fails.
    func unwrapPreviousTimeRange() throws -> AnalyticsHubTimeRange {
        guard let previousTimeRange = selectionDelegate.previousTimeRange else {
            throw TimeRangeGeneratorError.previousRangeGenerationFailed
        }
        return previousTimeRange
    }

    /// Generates a date description of the previous time range set internally.
    /// - Returns the Time range in a UI friendly format. If the previous time range is not available,
    /// then returns an presentable error message.
    func generateCurrentRangeDescription() -> String {
        guard let currentTimeRangeDescription = selectionDelegate.currentRangeDescription else {
            return Localization.noCurrentPeriodAvailable
        }
        return currentTimeRangeDescription
    }

    /// Generates a date description of the previous time range set internally.
    /// - Returns the Time range in a UI friendly format. If the previous time range is not available,
    /// then returns an presentable error message.
    func generatePreviousRangeDescription() -> String {
        guard let previousTimeRangeDescription = selectionDelegate.previousRangeDescription else {
            return Localization.noPreviousPeriodAvailable
        }
        return previousTimeRangeDescription
    }
}

// MARK: - Time Range Selection Type
extension AnalyticsHubTimeRangeSelection {
    enum SelectionType: CaseIterable {
        case today
        case yesterday
        case lastWeek
        case lastMonth
        case weekToDate
        case monthToDate
        case yearToDate

        var description: String {
            get {
                switch self {
                case .today:
                    return Localization.today
                case .yesterday:
                    return Localization.yesterday
                case .lastWeek:
                    return Localization.lastWeek
                case .lastMonth:
                    return Localization.lastMonth
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
}

// MARK: - Constants
extension AnalyticsHubTimeRangeSelection {

    enum TimeRangeGeneratorError: Error {
        case selectedRangeGenerationFailed
        case previousRangeGenerationFailed
    }

    enum Localization {
        static let today = NSLocalizedString("Today", comment: "Title of the Analytics Hub Today's selection range")
        static let yesterday = NSLocalizedString("Yesterday", comment: "Title of the Analytics Hub Yesterday selection range")
        static let lastWeek = NSLocalizedString("Last Week", comment: "Title of the Analytics Hub Last Week selection range")
        static let lastMonth = NSLocalizedString("Last Month", comment: "Title of the Analytics Hub Last Month selection range")
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
