import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// Handles `woocommerce.com/mobile/analytics?metric=<rawValue>&range=<rawValue>`, the deep
/// link emitted by Store Stats widget metric cells. Maps to a focused Analytics Hub card
/// when both parameters parse, otherwise falls back to opening the hub at its default state.
///
struct ReportsRoute: Route {
    private let deepLinkNavigator: DeepLinkNavigator
    private let analytics: Analytics

    init(deepLinkNavigator: DeepLinkNavigator,
         analytics: Analytics = ServiceLocator.analytics) {
        self.deepLinkNavigator = deepLinkNavigator
        self.analytics = analytics
    }

    func canHandle(subPath: String) -> Bool {
        subPath == StoreMetricsReportRoute.subpath
    }

    func perform(for subPath: String, with parameters: [String: String]) -> Bool {
        guard subPath == StoreMetricsReportRoute.subpath else { return false }

        let metricRaw = parameters[StoreMetricsReportRoute.QueryKey.metric]
        let rangeRaw = parameters[StoreMetricsReportRoute.QueryKey.range]
        let sourceRaw = parameters[StoreMetricsReportRoute.QueryKey.source]

        let destination: AnalyticsHubDestination = {
            guard let card = metricRaw.flatMap(WidgetMetricMapping.cardType(forMetricRawValue:)),
                  let range = rangeRaw.flatMap(WidgetMetricMapping.selectionType(forRangeRawValue:)) else {
                return .defaultHub
            }
            return .focusedCard(card: card, range: range)
        }()

        if sourceRaw == StoreMetricsReportRoute.Source.storeInfoWidget {
            analytics.track(event: .Widgets.storeStatsWidgetMetricTapped(metric: metricRaw, range: rangeRaw))
        }

        deepLinkNavigator.navigate(to: destination)
        return true
    }
}

/// Maps the widget-side stable raw values (`StoreInfoMetricType`, `StoreStatsWidgetDateRange`)
/// onto the in-app Analytics Hub types. The widget targets exclude these app types and the
/// app target excludes the widget enums, so the raw-value strings are the contract that
/// crosses the boundary and must stay in sync with the widget definitions.
///
enum WidgetMetricMapping {
    /// Mirrors `StoreInfoMetricType` raw values defined in `WooCommerce/StoreWidgets/StoreInfoMetricType.swift`.
    /// Sub-card granularity (e.g. Total Sales vs. Net Sales within the Revenue card) is not
    /// modelled — both fall through to `.revenue` and the user reads the right cell visually.
    ///
    static func cardType(forMetricRawValue rawValue: String) -> AnalyticsCard.CardType? {
        switch rawValue {
        case "revenue", "netSales":
            return .revenue
        case "orders", "averageOrderValue":
            return .orders
        case "itemsSold":
            return .products
        case "visitors", "conversion":
            return .sessions
        default:
            return nil
        }
    }

    /// Mirrors `StoreStatsWidgetDateRange` raw values defined in
    /// `WooCommerce/StoreWidgets/StoreStatsWidgetDateRange.swift`. Cases were chosen 1:1 with
    /// `AnalyticsHubTimeRangeSelection.SelectionType` so the mapping is mechanical.
    ///
    static func selectionType(forRangeRawValue rawValue: String) -> AnalyticsHubTimeRangeSelection.SelectionType? {
        switch rawValue {
        case "today": return .today
        case "yesterday": return .yesterday
        case "lastWeek": return .lastWeek
        case "lastMonth": return .lastMonth
        case "weekToDate": return .weekToDate
        case "monthToDate": return .monthToDate
        default: return nil
        }
    }
}
