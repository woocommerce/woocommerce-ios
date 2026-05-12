import Testing
import WidgetKit
@testable import WooCommerce

struct WidgetSnapshotTests {

    @Test func storeStats_with_default_dateRange_and_default_metrics_prefix_is_default() {
        // Given
        let metrics = Array(StoreStatsConfigurationIntent.defaultMetrics.prefix(4))
        let configuration: WidgetSnapshot.Configuration = .storeStats(
            dateRange: StoreStatsConfigurationIntent.defaultDateRange,
            metrics: metrics
        )

        // Then
        #expect(configuration.isDefault == true)
    }

    @Test func storeStats_with_reordered_metrics_is_not_default() {
        // Given
        let reordered: [StoreInfoMetricType] = [.orders, .revenue, .itemsSold, .averageOrderValue]
        let configuration: WidgetSnapshot.Configuration = .storeStats(
            dateRange: StoreStatsConfigurationIntent.defaultDateRange,
            metrics: reordered
        )

        // Then
        #expect(configuration.isDefault == false)
    }

    @Test func storeStats_with_non_default_dateRange_is_not_default() {
        // Given
        let metrics = Array(StoreStatsConfigurationIntent.defaultMetrics.prefix(2))
        let configuration: WidgetSnapshot.Configuration = .storeStats(
            dateRange: .last7Days,
            metrics: metrics
        )

        // Then
        #expect(configuration.isDefault == false)
    }

    @Test func storeStats_with_subset_of_default_metrics_in_order_is_default() {
        // Given - only 2 metrics matching the first 2 of the default priority list
        let metrics = Array(StoreStatsConfigurationIntent.defaultMetrics.prefix(2))
        let configuration: WidgetSnapshot.Configuration = .storeStats(
            dateRange: StoreStatsConfigurationIntent.defaultDateRange,
            metrics: metrics
        )

        // Then
        #expect(configuration.isDefault == true)
    }

    @Test func unconfigured_reports_nil_for_isDefault() {
        // Given
        let configuration: WidgetSnapshot.Configuration = .unconfigured

        // Then
        #expect(configuration.isDefault == nil)
    }

    @Test func snapshots_with_same_tiles_are_equal_and_hash_equal() {
        // Given
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(dateRange: .today, metrics: [.revenue, .orders])
        )

        // When
        let snapshotA = WidgetSnapshot(tiles: [tile])
        let snapshotB = WidgetSnapshot(tiles: [tile])

        // Then
        #expect(snapshotA == snapshotB)
        #expect(snapshotA.hashValue == snapshotB.hashValue)
    }

    @Test func snapshots_with_different_metric_order_are_not_equal() {
        // Given
        let tileA = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(dateRange: .today, metrics: [.revenue, .orders])
        )
        let tileB = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(dateRange: .today, metrics: [.orders, .revenue])
        )

        // Then
        #expect(WidgetSnapshot(tiles: [tileA]) != WidgetSnapshot(tiles: [tileB]))
    }

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

    @Test func snapshots_with_different_date_range_are_not_equal() {
        // Given
        let tileA = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(dateRange: .today, metrics: [.revenue, .orders])
        )
        let tileB = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(dateRange: .last7Days, metrics: [.revenue, .orders])
        )

        // Then
        #expect(WidgetSnapshot(tiles: [tileA]) != WidgetSnapshot(tiles: [tileB]))
    }
}
