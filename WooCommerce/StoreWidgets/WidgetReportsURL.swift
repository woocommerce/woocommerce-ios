import Foundation

/// Builds `https://woocommerce.com/mobile/analytics?metric=<rawValue>&range=<rawValue>&source=store-info-widget` —
/// the deep link a widget metric cell opens when tapped. URL shape is owned by
/// `StoreMetricsReportRoute`, the cross-target contract shared with the host app's
/// `ReportsRoute`.
enum WidgetReportsURL {
    static func url(for metric: StoreInfoMetricType, range: StoreStatsWidgetDateRange) -> URL? {
        var components = URLComponents()
        components.scheme = StoreMetricsReportRoute.scheme
        components.host = StoreMetricsReportRoute.host
        components.path = StoreMetricsReportRoute.path
        components.queryItems = [
            URLQueryItem(name: StoreMetricsReportRoute.QueryKey.metric, value: metric.rawValue),
            URLQueryItem(name: StoreMetricsReportRoute.QueryKey.range, value: range.rawValue),
            URLQueryItem(name: StoreMetricsReportRoute.QueryKey.source, value: StoreMetricsReportRoute.Source.storeInfoWidget)
        ]
        return components.url
    }
}
