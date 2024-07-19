import Foundation

/// Represents analytics reports the app can link to on the store's web admin
struct AnalyticsWebReport {

    /// Supported types of analytics reports
    enum ReportType: String {
        case revenue
        case orders
        case products
        case bundles
        case giftCards
        case googlePrograms
    }

    /// Provides the URL for a web analytics report
    /// - Parameters:
    ///   - report: Type of analytics report
    ///   - timeRange: Time range for the report
    ///   - storeAdminURL: The store's wp-admin URL
    ///   - timeZone: Timezone used to parse a custom period's start and end date
    ///
    static func getUrl(for report: ReportType,
                       timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
                       storeAdminURL: String? = ServiceLocator.stores.sessionManager.defaultSite?.adminURL,
                       timeZone: TimeZone = .siteTimezone) -> URL? {
        guard let storeAdminURL else {
            return nil
        }

        var reportURLComponents = URLComponents(string: storeAdminURL + "admin.php")
        var reportQueryParams = [
            "page": "wc-admin",
            "path": getPath(for: report),
            "period": getPeriod(for: timeRange),
            "compare": "previous_period"
        ]

        if case let .custom(startDate, endDate) = timeRange {
            let dateFormatter = DateFormatter.Defaults.yearMonthDayDateFormatter
            dateFormatter.timeZone = timeZone
            reportQueryParams["after"] = dateFormatter.string(from: startDate)
            reportQueryParams["before"] = dateFormatter.string(from: endDate)
        }

        reportURLComponents?.queryItems = reportQueryParams.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        return reportURLComponents?.url
    }

    /// Gets the path parameter for the web report, based on the provided report type
    ///
    private static func getPath(for reportType: ReportType) -> String {
        switch reportType {
        case .revenue:
            return "/analytics/revenue"
        case .orders:
            return "/analytics/orders"
        case .products:
            return "/analytics/products"
        case .bundles:
            return "/analytics/bundles"
        case .giftCards:
            return "/analytics/gift-cards"
        case .googlePrograms:
            return "/google/reports"
        }
    }

    /// Gets the period parameter for the web report, based on the provided time range
    ///
    private static func getPeriod(for timeRange: AnalyticsHubTimeRangeSelection.SelectionType) -> String {
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
        }
    }
}
