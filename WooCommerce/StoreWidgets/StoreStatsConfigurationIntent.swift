import AppIntents
import WidgetKit

/// Configuration intent for the Store Stats widget.
///
/// Surfaces the user-facing widget settings (long-press → Edit Widget). The `store` picker is
/// added by a later ticket on top of `dateRange` and `metrics`.
///
struct StoreStatsConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Store Stats"
    static var description = IntentDescription("Choose how the WooCommerce stats widget is displayed.")

    static let defaultDateRange: StoreStatsWidgetDateRange = .today

    static let defaultMetrics: [StoreInfoMetricType] = [
        .revenue, .orders, .itemsSold, .averageOrderValue,
        .netSales, .visitors, .conversion
    ]

    static let metricsSlotCounts: [WidgetFamily: Int] = [
        .systemSmall: 2,
        .systemMedium: 4,
        .systemLarge: 7
    ]

    @Parameter(title: "Date Range", default: .today)
    var dateRange: StoreStatsWidgetDateRange

    /// User-selected metric set, in display order.
    ///
    /// The `size:` map drives iOS's family-aware fixed-slot rendering — small shows 2 metrics,
    /// medium 4, and large 7. The picker shows the full catalog; metrics whose data isn't
    /// available for the user's auth mode (`visitors`, `conversion` on self-hosted) render
    /// with the standard "-" placeholder in the cell.
    ///
    /// The default lists the full catalog in priority order so iOS persists enough state
    /// to cover the largest family and available choices on first install. After a resize-up,
    /// `StoreInfoProvider.resolveMetricSelection` tops up undersized arrays from the same
    /// priority order so the widget body renders identically to a fresh install at the new
    /// family.
    ///
    @Parameter(
        title: "Metrics",
        default: [
            .revenue, .orders, .itemsSold, .averageOrderValue,
            .netSales, .visitors, .conversion
        ],
        size: [
            .systemSmall: .init(exactly: 2),
            .systemMedium: .init(exactly: 4),
            .systemLarge: .init(exactly: 7),
        ],
        query: AvailableMetricsQuery()
    )
    var metrics: [StoreInfoMetricType]
}
