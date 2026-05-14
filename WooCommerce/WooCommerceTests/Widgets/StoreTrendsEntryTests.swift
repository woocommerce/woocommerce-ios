import Foundation
import Testing
import WooFoundation
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

    @Test func presentable_metric_carries_chart_trend_and_range_aware_deeplink() throws {
        // Given - a data entry shaped like what the Trends provider hands the rectangular widget:
        // a single chart-backed metric with previous-period value and an interval series.
        let currencySettings = CurrencySettings()
        let chartSeries = (0..<6).map { index in
            MetricChartPoint(date: Date(timeIntervalSinceReferenceDate: Double(index * 86_400)),
                             value: Double(80 + index * 10))
        }
        let metric = StoreInfoMetric(
            type: .revenue,
            value: .currency(Decimal(123_456), currencySettings),
            previousValue: .currency(Decimal(100_000), currencySettings),
            chartSeries: chartSeries
        )
        let data = StoreInfoData(
            range: "Last Week",
            name: "Test Store",
            revenue: "$123,456",
            revenueCompact: "$123k",
            visitors: "67",
            orders: "23",
            conversion: "34%",
            updatedTime: "10:24 PM",
            metrics: [metric],
            dateRange: .lastWeek
        )

        // When
        let presentable = try #require(data.presentableMetrics.first)

        // Then
        #expect(data.dateRange == .lastWeek)
        #expect((presentable.chartData?.count ?? 0) > 1)
        #expect(presentable.trend?.direction == .up)
        #expect(presentable.tapURL == WidgetReportsURL.url(for: .revenue, range: .lastWeek))
    }
}
