import Foundation

/// Builds `https://woocommerce.com/mobile/analytics?metric=<rawValue>&range=<rawValue>` —
/// the deep link a widget metric cell opens when tapped.
enum WidgetReportsURL {
    static func url(for metric: StoreInfoMetricType, range: StoreStatsWidgetDateRange) -> URL? {
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = Constants.path
        components.queryItems = [
            URLQueryItem(name: Constants.metricQueryKey, value: metric.rawValue),
            URLQueryItem(name: Constants.rangeQueryKey, value: range.rawValue)
        ]
        return components.url
    }

    enum Constants {
        static let scheme = "https"
        static let host = "woocommerce.com"
        static let path = "/mobile/analytics"
        static let metricQueryKey = "metric"
        static let rangeQueryKey = "range"
    }
}
