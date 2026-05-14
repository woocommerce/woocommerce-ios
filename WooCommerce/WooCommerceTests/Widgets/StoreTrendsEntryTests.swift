import Foundation
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

    @Test func placeholder_entry_provides_chart_trend_and_range_for_trends_metric() throws {
        // When
        let entry = StoreInfoProvider.placeholderEntry(dateRange: .lastWeek, metrics: [.revenue])

        // Then
        guard case .data(let data) = entry else {
            Issue.record("Expected placeholder entry to provide sample data")
            return
        }

        let metric = try #require(data.presentableMetrics.first)
        #expect(data.dateRange == .lastWeek)
        #expect((metric.chartData?.count ?? 0) > 1)
        #expect(metric.trend?.direction == .up)
        #expect(metric.tapURL == WidgetReportsURL.url(for: .revenue, range: .lastWeek))
    }
}
