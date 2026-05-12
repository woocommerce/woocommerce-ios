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
        .netSales
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
    /// The `size:` map drives iOS's family-aware rendering — small shows exactly 2 metrics,
    /// medium exactly 4, and large allows 5-7. The picker hides metrics whose data isn't
    /// available with site credentials (`visitors`, `conversion` today) for self-hosted users,
    /// while persisted configurations with those metrics still render the standard "-"
    /// placeholder in the cell.
    ///
    /// The default lists only metrics available with site credentials so first-install
    /// self-hosted large widgets start with intentional content instead of unreachable
    /// placeholder rows.
    ///
    @Parameter(
        title: "Metrics",
        default: [
            .revenue, .orders, .itemsSold, .averageOrderValue,
            .netSales
        ],
        size: [
            .systemSmall: .init(exactly: 2),
            .systemMedium: .init(exactly: 4),
            .systemLarge: .init(min: 5, max: 7),
        ],
        query: AvailableMetricsQuery()
    )
    var metrics: [StoreInfoMetricType]
}
