import Foundation
import Yosemite

// MARK: - DateRangeModel
//
struct DateRangeModel: Hashable {
    var title: String
    var range: AnalyticsRange
}

struct DateRanges {
    var objectsArray: [DateRangeModel] = [
        DateRangeModel(title: Localization.today, range: .today),
        DateRangeModel(title: Localization.yesterday, range: .yesterday),
        DateRangeModel(title: Localization.lastWeek, range: .lastWeek),
        DateRangeModel(title: Localization.lastMonth, range: .lastMonth),
        DateRangeModel(title: Localization.lastQuarter, range: .lastQuarter),
        DateRangeModel(title: Localization.lastYear, range: .lastYear),
        DateRangeModel(title: Localization.weekToDate, range: .weekToDate),
        DateRangeModel(title: Localization.monthToDate, range: .monthToDate),
        DateRangeModel(title: Localization.quarterToDate, range: .quarterToDate),
        DateRangeModel(title: Localization.yearToDate, range: .yearToDate),
    ]
}

private extension DateRanges {
    enum Localization {
        static let today = NSLocalizedString("Today", comment: "Title of today date range.")
        static let yesterday = NSLocalizedString("Yesterday", comment: "Title of yesterday date range.")
        static let lastWeek = NSLocalizedString("Last Week", comment: "Title of yesterday date range.")
        static let lastMonth = NSLocalizedString("Last Month", comment: "Title of last month date range.")
        static let lastQuarter = NSLocalizedString("Last Quarter", comment: "Title of last quarter date range.")
        static let lastYear = NSLocalizedString("Last Year", comment: "Title of last year date range.")
        static let weekToDate = NSLocalizedString("Week to date", comment: "Title of week to date date range.")
        static let monthToDate = NSLocalizedString("Month to date", comment: "Title of month to date date range.")
        static let quarterToDate = NSLocalizedString("Quarter to date", comment: "Title of quarter to date date range.")
        static let yearToDate = NSLocalizedString("Year to date", comment: "Title of year to date date range.")
    }
}
