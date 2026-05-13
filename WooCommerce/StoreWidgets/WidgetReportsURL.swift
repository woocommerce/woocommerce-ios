import Foundation

/// Builds `https://woocommerce.com/mobile/analytics?metric=<rawValue>&range=<rawValue>&source=store-info-widget` —
/// the deep link a widget metric cell opens when tapped. The `source` parameter lets the
/// host-app route attribute the tap to this widget if another caller ever produces the
/// same URL shape (e.g. an in-app banner or a marketing link).
///
/// The string constants below are the wire-format contract shared with the host app's
/// `ReportsRoute` (`WooCommerce/Classes/Universal Links/Routes/ReportsRoute.swift`). They
/// are duplicated rather than referenced because the WooCommerce target and the
/// StoreWidgetsExtension target sync separate source roots (`Classes/` and `StoreWidgets/`
/// respectively) and share no compilable folder. Any change here MUST be mirrored in
/// `ReportsRoute.Constants` and the corresponding tests on both sides.
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
        /// Mirrors `WooConstants.storeInfoWidgetKind` as a URL-friendly slug, and is mirrored
        /// in `ReportsRoute.Constants.storeInfoWidgetSource` on the host-app side.
        static let sourceValue = "store-info-widget"
    }
}
