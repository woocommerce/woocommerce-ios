import Testing
@testable import WooCommerce

struct StoreTrendsEntryTests {

    @Test func preserves_unavailable_metric_and_range() {
        // When
        let entry = StoreTrendsEntry(
            storeInfoEntry: .error,
            dateRange: .last30Days,
            metrics: [.orders]
        )

        // Then
        #expect(entry.unavailableMetricTitle == StoreInfoMetricType.orders.displayName)
        #expect(entry.compactRange == StoreStatsWidgetDateRange.last30Days.localizedCompactRangeLabel)
    }

    @Test func uses_first_visible_metric_for_unavailable_state() {
        // When
        let entry = StoreTrendsEntry(
            storeInfoEntry: .error,
            dateRange: .last7Days,
            metrics: [.itemsSold]
        )

        // Then
        #expect(entry.unavailableMetricTitle == StoreInfoMetricType.itemsSold.displayName)
        #expect(entry.compactRange == StoreStatsWidgetDateRange.last7Days.localizedCompactRangeLabel)
    }
}
