import Foundation
import Yosemite

enum AnalyticsHubTimeRangeSelectionType: CaseIterable {
    case today
    case yesterday
    case lastWeek
    case lastMonth
    case lastYear
    case weekToDate
    case monthToDate
    case yearToDate

    var description: String {
        switch self {
        case .today:
            return Localization.today
        case .yesterday:
            return Localization.yesterday
        case .lastWeek:
            return Localization.lastWeek
        case .lastMonth:
            return Localization.lastMonth
        case .lastYear:
            return Localization.lastYear
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

    enum Localization {
        static let today = NSLocalizedString("Today", comment: "Title of the Analytics Hub Today's selection range")
        static let yesterday = NSLocalizedString("Yesterday", comment: "Title of the Analytics Hub Yesterday selection range")
        static let lastWeek = NSLocalizedString("Last Week", comment: "Title of the Analytics Hub Last Week selection range")
        static let lastMonth = NSLocalizedString("Last Month", comment: "Title of the Analytics Hub Last Month selection range")
        static let lastYear = NSLocalizedString("Last Year", comment: "Title of the Analytics Hub Last Year selection range")
        static let weekToDate = NSLocalizedString("Week to Date", comment: "Title of the Analytics Hub Week to Date selection range")
        static let monthToDate = NSLocalizedString("Month to Date", comment: "Title of the Analytics Hub Month to Date selection range")
        static let yearToDate = NSLocalizedString("Year to Date", comment: "Title of the Analytics Hub Year to Date selection range")
    }
}
