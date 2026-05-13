import Testing
import WidgetKit
@testable import WooCommerce

struct StoreStatsConfigurationIntentTests {

    // MARK: - Family-aware metric slot count

    @Test func systemSmall_keeps_correct_metric_slot_count() {
        #expect(StoreStatsConfigurationIntent.metricsSlotCounts[.systemSmall] == 2)
    }

    @Test func accessoryRectangular_keeps_correct_metric_slot_count() {
        #expect(StoreStatsConfigurationIntent.metricsSlotCounts[.accessoryRectangular] == 1)
    }

    @Test func systemMedium_keeps_correct_metric_slot_count() {
        #expect(StoreStatsConfigurationIntent.metricsSlotCounts[.systemMedium] == 4)
    }

    @Test func systemLarge_keeps_correct_metric_slot_count() {
        #expect(StoreStatsConfigurationIntent.metricsSlotCounts[.systemLarge] == 7)
    }

    // MARK: - Family-aware metric resolution

    @Test func accessoryRectangular_resolves_to_one_metric() {
        // When
        let metrics = StoreStatsConfigurationIntent.resolveMetricSelection(
            requested: [.revenue, .orders],
            family: .accessoryRectangular
        )

        // Then
        #expect(metrics == [.revenue])
    }

    @Test func accessoryRectangular_keeps_selected_chart_backed_metric() {
        // When
        let metrics = StoreStatsConfigurationIntent.resolveMetricSelection(
            requested: [.orders],
            family: .accessoryRectangular
        )

        // Then
        #expect(metrics == [.orders])
    }

    @Test func accessoryRectangular_replaces_visitors_with_default_chart_backed_metric() {
        // When
        let metrics = StoreStatsConfigurationIntent.resolveMetricSelection(
            requested: [.visitors],
            family: .accessoryRectangular
        )

        // Then
        #expect(metrics == [.revenue])
    }

    @Test func accessoryRectangular_uses_first_chart_backed_metric_from_selection() {
        // When
        let metrics = StoreStatsConfigurationIntent.resolveMetricSelection(
            requested: [.conversion, .itemsSold],
            family: .accessoryRectangular
        )

        // Then
        #expect(metrics == [.itemsSold])
    }
}
