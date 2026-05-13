import Foundation

/// Builds `https://woocommerce.com/mobile/analytics?metric=<rawValue>&range=<rawValue>&source=store-info-widget` —
/// the deep link a widget metric cell opens when tapped. The `source` parameter lets the
/// host-app route attribute the tap to this widget if another caller ever produces the
/// same URL shape (e.g. an in-app banner or a marketing link).
enum WidgetReportsURL {
    static func url(for metric: StoreInfoMetricType, range: StoreStatsWidgetDateRange) -> URL? {
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = Constants.path
        components.queryItems = [
            URLQueryItem(name: Constants.metricQueryKey, value: metric.rawValue),
            URLQueryItem(name: Constants.rangeQueryKey, value: range.rawValue),
            URLQueryItem(name: Constants.sourceQueryKey, value: Constants.sourceValue)
        ]
        return components.url
    }

    enum Constants {
        static let scheme = "https"
        static let host = "woocommerce.com"
        static let path = "/mobile/analytics"
        static let metricQueryKey = "metric"
        static let rangeQueryKey = "range"
        static let sourceQueryKey = "source"
        /// Mirrors `WooConstants.storeInfoWidgetKind` as a URL-friendly slug. Kept in sync
        /// with the host-app route via the wire-format string contract (the constant lives
        /// in the main app target, excluded from this widget extension).
        static let sourceValue = "store-info-widget"
    }
}
