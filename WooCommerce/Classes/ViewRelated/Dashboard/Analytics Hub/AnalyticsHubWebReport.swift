import Foundation

/// Represents analytics reports the app can link to on the store's web admin
struct AnalyticsHubWebReport {

    /// Supported types of analytics reports
    enum ReportType {
        case revenue
        case orders
        case products
    }

    /// Provides the URL for a web analytics report
    /// - Parameters:
    ///   - report: Type of analytics report
    ///   - period: Time range for the report
    ///   - storeAdminURL: The store's wp-admin URL
    ///
    static func getUrl(for report: ReportType,
                       timeRange: AnalyticsHubTimeRangeSelection.SelectionType?,
                       storeAdminURL: String? = ServiceLocator.stores.sessionManager.defaultSite?.adminURL,
                       timeZone: TimeZone = .siteTimezone) -> URL? {
        guard let storeAdminURL else {
            return nil
        }

        let path = getPath(for: report)
        let defaultReportString = storeAdminURL + "admin.php?page=wc-admin&path=\(path)"

        // Build the web report URL based on the time range
        // Note: the `compare` parameter only applies if the period is also specified
        let period = getPeriod(for: timeRange)
        switch (timeRange, period) {
        case let (.custom(startDate, endDate), .some(period)):
            let dateFormatter = DateFormatter.Defaults.yearMonthDayDateFormatter
            dateFormatter.timeZone = timeZone
            let after = dateFormatter.string(from: startDate)
            let before = dateFormatter.string(from: endDate)
            return URL(string: defaultReportString + "&period=\(period)&after=\(after)&before=\(before)&compare=previous_period")
        case let (_, .some(period)):
            return URL(string: defaultReportString + "&period=\(period)&compare=previous_period")
        default:
            return URL(string: defaultReportString)
        }
    }

    /// Gets the path parameter for the web report, based on the provided report type
    ///
    private static func getPath(for reportType: ReportType) -> String {
        switch reportType {
        case .revenue:
            return "%2Fanalytics%2Frevenue"
        case .orders:
            return "%2Fanalytics%2Forders"
        case .products:
            return "%2Fanalytics%2Fproducts"
        }
    }

    /// Gets the period parameter for the web report, based on the provided time range
    ///
    private static func getPeriod(for timeRange: AnalyticsHubTimeRangeSelection.SelectionType?) -> String? {
        switch timeRange {
        case .custom:
            return "custom"
        case .today:
            return "today"
        case .yesterday:
            return "yesterday"
        case .lastWeek:
            return "last_week"
        case .lastMonth:
            return "last_month"
        case .lastQuarter:
            return "last_quarter"
        case .lastYear:
            return "last_year"
        case .weekToDate:
            return "week"
        case .monthToDate:
            return "month"
        case .quarterToDate:
            return "quarter"
        case .yearToDate:
            return "year"
        default:
            return nil
        }
    }
}
