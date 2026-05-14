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

    @Test func storeInfo_tile_from_intent_uses_storeStats_configuration_intent() {
        // Given
        var intent = StoreStatsConfigurationIntent()
        intent.dateRange = .last7Days
        intent.metrics = [.revenue, .orders]

        // When
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            intent: intent
        )

        // Then
        #expect(tile.kind == WooConstants.storeInfoWidgetKind)
        #expect(tile.family == .systemMedium)
        #expect(tile.configuration == .storeStats(dateRange: .last7Days, metrics: [.revenue, .orders, .itemsSold, .averageOrderValue]))
    }

    @Test func storeTrends_tile_from_intent_uses_storeTrends_configuration_intent() {
        // Given
        var intent = StoreTrendsConfigurationIntent()
        intent.dateRange = .last30Days
        intent.metrics = [.visitors]

        // When
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeTrendsWidgetKind,
            family: .accessoryRectangular,
            intent: intent
        )

        // Then
        #expect(tile.kind == WooConstants.storeTrendsWidgetKind)
        #expect(tile.family == .accessoryRectangular)
        #expect(tile.configuration == .storeStats(dateRange: .last30Days, metrics: [.revenue]))
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
