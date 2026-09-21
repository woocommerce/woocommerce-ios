import Foundation
import WidgetKit

/// Timeline entry for the Trends lock-screen widget. Pairs the upstream `StoreInfoEntry`
/// (the data the provider fetched) with the labels the rectangular UI needs even when
/// the data path fails — the metric title shown in the unavailable state and the compact
/// date-range label.
///
struct StoreTrendsEntry: TimelineEntry {
    let date: Date
    let storeInfoEntry: StoreInfoEntry
    let unavailableMetricTitle: String
    let compactRange: String

    init(date: Date = Date(),
         storeInfoEntry: StoreInfoEntry,
         dateRange: StoreStatsWidgetDateRange,
         metrics visibleMetrics: [StoreInfoMetricType]) {
        self.date = date
        self.storeInfoEntry = storeInfoEntry
        self.unavailableMetricTitle = visibleMetrics.first?.displayName ?? StoreInfoMetricType.revenue.displayName
        self.compactRange = dateRange.localizedCompactRangeLabel
    }
}
