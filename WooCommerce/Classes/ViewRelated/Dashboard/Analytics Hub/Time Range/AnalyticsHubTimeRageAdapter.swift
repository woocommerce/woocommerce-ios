import Foundation

/// Type that help us converting and querying common data from the ranges supported for the Analytics Hub.
/// Currently we have two range enum types, One for the list UI and one for the supported ranges in the business layer.
/// This adapter help us sharing some common meta data between those two ranges.
///
struct AnalyticsHubRangeAdapter {

    /// Converts an `AnalyticsHubTimeRangeSelection.SelectionType` range into a `AnalyticsTimeRangeCard.Range`.
    ///
    static func timeCardRange(from analyticsHubRange: AnalyticsHubTimeRangeSelection.SelectionType) -> AnalyticsTimeRangeCard.Range {
        switch analyticsHubRange {
        case .custom:
            return .custom
        case .today:
            return .today
        case .yesterday:
            return .yesterday
        case .lastWeek:
            return .lastWeek
        case .lastMonth:
            return .lastMonth
        case .lastQuarter:
            return .lastQuarter
        case .lastYear:
            return .lastYear
        case .weekToDate:
            return .weekToDate
        case .monthToDate:
            return .monthToDate
        case .quarterToDate:
            return .quarterToDate
        case .yearToDate:
            return .yearToDate
        }
    }

    /// Converts an `AnalyticsTimeRangeCard.Range` into a `AnalyticsHubTimeRangeSelection.SelectionType` range.
    ///
    static func analyticsHubRange(from timeCardRange: AnalyticsTimeRangeCard.Range) -> AnalyticsHubTimeRangeSelection.SelectionType {
        switch timeCardRange {
        case .custom:
            return .custom(start: Date(), end: Date())
        case .today:
            return .today
        case .yesterday:
            return .yesterday
        case .lastWeek:
            return .lastWeek
        case .lastMonth:
            return .lastMonth
        case .lastQuarter:
            return .lastQuarter
        case .lastYear:
            return .lastYear
        case .weekToDate:
            return .weekToDate
        case .monthToDate:
            return .monthToDate
        case .quarterToDate:
            return .quarterToDate
        case .yearToDate:
            return .yearToDate
        }
    }

    /// Returns the desciption of the provided `AnalyticsHubTimeRangeSelection.SelectionType`range.
    ///
    static func description(from analyticsHubRange: AnalyticsHubTimeRangeSelection.SelectionType) -> String {
        switch analyticsHubRange {
        case .custom:
            return Localization.custom
        case .today:
            return Localization.today
        case .yesterday:
            return Localization.yesterday
        case .lastWeek:
            return Localization.lastWeek
        case .lastMonth:
            return Localization.lastMonth
        case .lastQuarter:
            return Localization.lastQuarter
        case .lastYear:
            return Localization.lastYear
        case .weekToDate:
            return Localization.weekToDate
        case .monthToDate:
            return Localization.monthToDate
        case .quarterToDate:
            return Localization.quarterToDate
        case .yearToDate:
            return Localization.yearToDate
        }
    }

    /// Returns the desciption of the provided `AnalyticsTimeRangeCard.Range`.
    ///
    static func description(from timeCardRange: AnalyticsTimeRangeCard.Range) -> String {
        switch timeCardRange {
        case .custom:
            return Localization.custom
        case .today:
            return Localization.today
        case .yesterday:
            return Localization.yesterday
        case .lastWeek:
            return Localization.lastWeek
        case .lastMonth:
            return Localization.lastMonth
        case .lastQuarter:
            return Localization.lastQuarter
        case .lastYear:
            return Localization.lastYear
        case .weekToDate:
            return Localization.weekToDate
        case .monthToDate:
            return Localization.monthToDate
        case .quarterToDate:
            return Localization.quarterToDate
        case .yearToDate:
            return Localization.yearToDate
        }
    }

    /// Returns the tracks identifier of the provided `AnalyticsHubTimeRangeSelection.SelectionType`.
    ///
    static func tracksIdentifier(from analyticsHubRange: AnalyticsHubTimeRangeSelection.SelectionType) -> String {
        switch analyticsHubRange {
        case .custom:
            return TracksIdentifier.custom
        case .today:
            return TracksIdentifier.today
        case .yesterday:
            return TracksIdentifier.yesterday
        case .lastWeek:
            return TracksIdentifier.lastWeek
        case .lastMonth:
            return TracksIdentifier.lastMonth
        case .lastQuarter:
            return TracksIdentifier.lastQuarter
        case .lastYear:
            return TracksIdentifier.lastYear
        case .weekToDate:
            return TracksIdentifier.weekToDate
        case .monthToDate:
            return TracksIdentifier.monthToDate
        case .quarterToDate:
            return TracksIdentifier.quarterToDate
        case .yearToDate:
            return TracksIdentifier.yearToDate
        }
    }

    /// Returns the tracks identifier of the provided `AnalyticsTimeRangeCard.Range`.
    ///
    static func tracksIdentifier(from timeCardRange: AnalyticsTimeRangeCard.Range) -> String {
        switch timeCardRange {
        case .custom:
            return TracksIdentifier.custom
        case .today:
            return TracksIdentifier.today
        case .yesterday:
            return TracksIdentifier.yesterday
        case .lastWeek:
            return TracksIdentifier.lastWeek
        case .lastMonth:
            return TracksIdentifier.lastMonth
        case .lastQuarter:
            return TracksIdentifier.lastQuarter
        case .lastYear:
            return TracksIdentifier.lastYear
        case .weekToDate:
            return TracksIdentifier.weekToDate
        case .monthToDate:
            return TracksIdentifier.monthToDate
        case .quarterToDate:
            return TracksIdentifier.quarterToDate
        case .yearToDate:
            return TracksIdentifier.yearToDate
        }
    }

    /// Extracts the dates from an analytics hub range custom type.
    ///
    static func customDates(from analyticsHubRange: AnalyticsHubTimeRangeSelection.SelectionType) -> (start: Date, end: Date)? {
        switch analyticsHubRange {
        case let .custom(startDate, endDate):
            return (startDate, endDate)
        default:
            return nil
        }
    }
}

// MARK: Constants

private extension AnalyticsHubRangeAdapter {
    enum TracksIdentifier {
        static let custom = "Custom"
        static let today  = "Today"
        static let yesterday = "Yesterday"
        static let lastWeek = "Last Week"
        static let lastMonth = "Last Month"
        static let lastQuarter = "Last Quarter"
        static let lastYear = "Last Year"
        static let weekToDate = "Week to Date"
        static let monthToDate = "Month to Date"
        static let quarterToDate = "Quarter to Date"
        static let yearToDate = "Year to Date"
    }

    enum Localization {
        static let custom = NSLocalizedString("Custom", comment: "Title of the Analytics Hub Custom selection range")
        static let today = NSLocalizedString("Today", comment: "Title of the Analytics Hub Today's selection range")
        static let yesterday = NSLocalizedString("Yesterday", comment: "Title of the Analytics Hub Yesterday selection range")
        static let lastWeek = NSLocalizedString("Last Week", comment: "Title of the Analytics Hub Last Week selection range")
        static let lastMonth = NSLocalizedString("Last Month", comment: "Title of the Analytics Hub Last Month selection range")
        static let lastQuarter = NSLocalizedString("Last Quarter", comment: "Title of the Analytics Hub Last Quarter selection range")
        static let lastYear = NSLocalizedString("Last Year", comment: "Title of the Analytics Hub Last Year selection range")
        static let weekToDate = NSLocalizedString("Week to Date", comment: "Title of the Analytics Hub Week to Date selection range")
        static let monthToDate = NSLocalizedString("Month to Date", comment: "Title of the Analytics Hub Month to Date selection range")
        static let quarterToDate = NSLocalizedString("Quarter to Date", comment: "Title of the Analytics Hub Quarter to Date selection range")
        static let yearToDate = NSLocalizedString("Year to Date", comment: "Title of the Analytics Hub Year to Date selection range")
    }
}

// MARK: Convenience Extensitons
extension AnalyticsTimeRangeCard.Range {

    var description: String {
        AnalyticsHubRangeAdapter.description(from: self)
    }

    var tracksIdentifier: String {
        AnalyticsHubRangeAdapter.tracksIdentifier(from: self)
    }

    var asAnalyticsHubRange: AnalyticsHubTimeRangeSelection.SelectionType {
        AnalyticsHubRangeAdapter.analyticsHubRange(from: self)
    }
}

extension AnalyticsHubTimeRangeSelection.SelectionType {
    var description: String {
        AnalyticsHubRangeAdapter.description(from: self)
    }

    var tracksIdentifier: String {
        AnalyticsHubRangeAdapter.tracksIdentifier(from: self)
    }

    var asTimeCardRange: AnalyticsTimeRangeCard.Range {
        AnalyticsHubRangeAdapter.timeCardRange(from: self)
    }

    /// Extracts the start date from custom range type.
    ///
    var startDate: Date? {
        AnalyticsHubRangeAdapter.customDates(from: self)?.start
    }

    /// Extracts the end date from custom range type.
    ///
    var endDate: Date? {
        AnalyticsHubRangeAdapter.customDates(from: self)?.end
    }
}
