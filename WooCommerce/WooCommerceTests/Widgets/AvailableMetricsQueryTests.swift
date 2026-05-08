import Testing
@testable import WooCommerce

struct AvailableMetricsQueryTests {

    @Test func allEntities_returns_none_before_metric_catalog() async throws {
        // When
        let entities = try await AvailableMetricsQuery().allEntities()

        // Then
        #expect(entities == [.none] + StoreStatsConfigurationIntent.defaultMetrics)
    }

    @Test func suggestedEntities_returns_none_before_metric_catalog() async throws {
        // When
        let entities = try await AvailableMetricsQuery().suggestedEntities()

        // Then
        #expect(entities == [.none] + StoreStatsConfigurationIntent.defaultMetrics)
    }

    @Test func entities_for_none_identifier_resolves_none() async throws {
        // When
        let entities = try await AvailableMetricsQuery().entities(for: [StoreInfoMetricType.none.id])

        // Then
        #expect(entities == [.none])
    }

    @Test func entities_for_reordered_identifiers_preserves_identifier_order() async throws {
        // When
        let entities = try await AvailableMetricsQuery().entities(for: [
            StoreInfoMetricType.orders.id,
            StoreInfoMetricType.none.id,
            StoreInfoMetricType.revenue.id
        ])

        // Then
        #expect(entities == [.orders, .none, .revenue])
    }
}
