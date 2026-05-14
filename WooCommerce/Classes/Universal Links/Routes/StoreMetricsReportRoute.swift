import Foundation

/// Wire-format contract for the Store Stats widget metric deep link. Single source of
/// truth for the URL the widget emits (`WidgetReportsURL`) and the host app's
/// `ReportsRoute` consumes.
///
/// This file must be a member of both the `WooCommerce` app target (consumer side) and
/// the `StoreWidgetsExtension` target (producer side). The two targets sync different
/// source roots and don't share a synced folder, so target membership is set explicitly
/// in the project file.
///
enum StoreMetricsReportRoute {
    static let scheme = "https"
    static let host = "woocommerce.com"
    static let path = "/mobile/analytics"
    /// Path segment that `UniversalLinkRouter` matches against after stripping the
    /// `/mobile/` prefix — i.e. the value `Route.canHandle(subPath:)` receives.
    static let subpath = "analytics"

    enum QueryKey {
        static let metric = "metric"
        static let range = "range"
        static let source = "source"
    }

    enum Source {
        /// Stamped by the Store Info widget cells so the route can attribute the tap to
        /// this widget if another caller ever produces the same URL shape. Mirrors
        /// `WooConstants.storeInfoWidgetKind` as a URL-friendly slug.
        static let storeInfoWidget = "store-info-widget"
    }
}
