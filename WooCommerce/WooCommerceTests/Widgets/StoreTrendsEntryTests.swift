import Testing
@testable import WooCommerce

struct StoreTrendsEntryTests {

    @Test func preserves_unavailable_metric_and_range() {
        // When
        let entry = StoreTrendsEntry(
            storeInfoEntry: .error,
            dateRange: .lastMonth,
            metrics: [.orders]
        )

        // Then
        #expect(entry.unavailableMetricTitle == StoreInfoMetricType.orders.displayName)
        #expect(entry.compactRange == StoreStatsWidgetDateRange.lastMonth.localizedCompactRangeLabel)
    }

    @Test func uses_first_visible_metric_for_unavailable_state() {
        // When
        let entry = StoreTrendsEntry(
            storeInfoEntry: .error,
            dateRange: .lastWeek,
            metrics: [.itemsSold]
        )

        // Then
        #expect(entry.unavailableMetricTitle == StoreInfoMetricType.itemsSold.displayName)
        #expect(entry.compactRange == StoreStatsWidgetDateRange.lastWeek.localizedCompactRangeLabel)
    }
}
