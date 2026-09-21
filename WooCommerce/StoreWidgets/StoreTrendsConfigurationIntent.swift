import AppIntents
import WidgetKit

/// Configuration intent for the Trends lock-screen widget.
///
/// The Trends widget shares the Store and Date Range controls with the Store Stats widget, but
/// exposes a chart-only metric picker because its rectangular UI always renders a small chart.
///
struct StoreTrendsConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Store Trends"
    static var description = IntentDescription("Choose how the WooCommerce trends widget is displayed.")

    static let defaultDateRange: StoreStatsWidgetDateRange = .today

    static let defaultMetrics: [StoreInfoMetricType] = [
        .revenue
    ]

    @Parameter(title: "Store")
    var store: StoreStatsStoreEntity?

    @Parameter(title: "Date Range", default: .today)
    var dateRange: StoreStatsWidgetDateRange

    @Parameter(
        title: "Metric",
        default: [
            .revenue
        ],
        size: [
            .accessoryRectangular: .init(exactly: 1)
        ],
        query: AvailableChartMetricsQuery()
    )
    var metrics: [StoreInfoMetricType]

    init() {
        store = StoreStatsStoreEntity.defaultStore
    }
}

extension StoreTrendsConfigurationIntent {
    /// Resolves stale or malformed persisted metric choices to one chart-backed metric.
    static func resolveMetricSelection(requested: [StoreInfoMetricType]) -> [StoreInfoMetricType] {
        [requested.first(where: \.supportsChart) ?? defaultChartBackedMetric]
    }

    private static var defaultChartBackedMetric: StoreInfoMetricType {
        defaultMetrics.first(where: \.supportsChart) ?? .revenue
    }
}
