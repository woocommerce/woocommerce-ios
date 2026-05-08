import Testing
import WidgetKit
@testable import WooCommerce

struct StoreInfoProviderMetricSelectionTests {

    @Test func resolveMetricSelection_preserves_none_for_small_family() {
        // When
        let resolved = StoreInfoProvider.resolveMetricSelection(
            requested: [.none, .orders],
            family: .systemSmall
        )

        // Then
        #expect(resolved == [.none, .orders])
    }

    @Test func resolveMetricSelection_preserves_none_for_medium_family() {
        // Given
        let requested: [StoreInfoMetricType] = [.revenue, .none, .orders, .visitors]

        // When
        let resolved = StoreInfoProvider.resolveMetricSelection(
            requested: requested,
            family: .systemMedium
        )

        // Then
        #expect(resolved == requested)
    }

    @Test func resolveMetricSelection_preserves_none_for_large_family() {
        // Given
        let requested: [StoreInfoMetricType] = [
            .revenue, .orders, .none, .averageOrderValue,
            .netSales, .visitors, .conversion
        ]

        // When
        let resolved = StoreInfoProvider.resolveMetricSelection(
            requested: requested,
            family: .systemLarge
        )

        // Then
        #expect(resolved == requested)
    }

    @Test func resolveMetricSelection_tops_up_missing_slots_around_explicit_none() {
        // When
        let resolved = StoreInfoProvider.resolveMetricSelection(
            requested: [.revenue, .none],
            family: .systemMedium
        )

        // Then
        #expect(resolved == [.revenue, .none, .orders, .itemsSold])
    }

    @Test func resolveMetricSelection_keeps_none_when_resizing_down() {
        // When
        let resolved = StoreInfoProvider.resolveMetricSelection(
            requested: [.revenue, .none, .orders, .visitors],
            family: .systemSmall
        )

        // Then
        #expect(resolved == [.revenue, .none])
    }

    @Test func resolveMetricSelection_returns_requested_metrics_for_non_home_screen_families() {
        // Given
        let requested: [StoreInfoMetricType] = [.none, .orders]

        // When
        let resolved = StoreInfoProvider.resolveMetricSelection(
            requested: requested,
            family: .accessoryCircular
        )

        // Then
        #expect(resolved == requested)
    }
}
