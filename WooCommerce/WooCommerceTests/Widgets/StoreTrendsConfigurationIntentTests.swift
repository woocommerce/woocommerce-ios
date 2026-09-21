import Testing
@testable import WooCommerce

struct StoreTrendsConfigurationIntentTests {

    @Test func metrics_query_only_returns_chart_backed_metrics() async throws {
        // When
        let metrics = try await AvailableChartMetricsQuery().suggestedEntities()

        // Then
        #expect(metrics == StoreInfoMetricType.allCases.filter(\.supportsChart))
        #expect(metrics.contains(.visitors) == false)
        #expect(metrics.contains(.conversion) == false)
    }

    @Test func resolves_to_one_chart_backed_metric() {
        // When
        let metrics = StoreTrendsConfigurationIntent.resolveMetricSelection(
            requested: [.revenue, .orders]
        )

        // Then
        #expect(metrics == [.revenue])
    }

    @Test func keeps_selected_chart_backed_metric() {
        // When
        let metrics = StoreTrendsConfigurationIntent.resolveMetricSelection(
            requested: [.orders]
        )

        // Then
        #expect(metrics == [.orders])
    }

    @Test func replaces_non_chart_metric_with_default_chart_backed_metric() {
        // When
        let metrics = StoreTrendsConfigurationIntent.resolveMetricSelection(
            requested: [.visitors]
        )

        // Then
        #expect(metrics == [.revenue])
    }

    @Test func uses_first_chart_backed_metric_from_selection() {
        // When
        let metrics = StoreTrendsConfigurationIntent.resolveMetricSelection(
            requested: [.conversion, .itemsSold]
        )

        // Then
        #expect(metrics == [.itemsSold])
    }
}
