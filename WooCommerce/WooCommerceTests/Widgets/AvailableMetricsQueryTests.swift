import Testing
@testable import WooCommerce

struct AvailableMetricsQueryTests {

    @Test func allEntities_returns_none_before_metric_catalog() async throws {
        // When
        let entities = try await AvailableMetricsQuery().allEntities()
        let expected: [StoreInfoMetricType] = [.none] + StoreStatsConfigurationIntent.defaultMetrics

        // Then
        #expect(entities == expected)
    }

    @Test func suggestedEntities_returns_none_before_metric_catalog() async throws {
        // When
        let entities = try await AvailableMetricsQuery().suggestedEntities()
        let expected: [StoreInfoMetricType] = [.none] + StoreStatsConfigurationIntent.defaultMetrics

        // Then
        #expect(entities == expected)
    }

    @Test func entities_for_none_identifier_resolves_none() async throws {
        // When
        let entities = try await AvailableMetricsQuery().entities(for: [StoreInfoMetricType.none.id])
        let expected: [StoreInfoMetricType] = [.none]

        // Then
        #expect(entities == expected)
    }

    @Test func entities_for_reordered_identifiers_preserves_identifier_order() async throws {
        // When
        let entities = try await AvailableMetricsQuery().entities(for: [
            StoreInfoMetricType.orders.id,
            StoreInfoMetricType.none.id,
            StoreInfoMetricType.revenue.id
        ])
        let expected: [StoreInfoMetricType] = [.orders, .none, .revenue]

        // Then
        #expect(entities == expected)
    }
}
