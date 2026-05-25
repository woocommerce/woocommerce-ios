import Testing
import WidgetKit
@testable import WooCommerce

struct WidgetSnapshotTests {

    @Test func storeInfo_tile_with_default_dateRange_and_default_metrics_prefix_is_default() {
        // Given
        let metrics = Array(StoreStatsConfigurationIntent.defaultMetrics.prefix(4))
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(
                dateRange: StoreStatsConfigurationIntent.defaultDateRange,
                metrics: metrics
            )
        )

        // Then
        #expect(tile.isDefault == true)
    }

    @Test func storeInfo_tile_with_reordered_metrics_is_not_default() {
        // Given
        let reordered: [StoreInfoMetricType] = [.orders, .revenue, .itemsSold, .averageOrderValue]
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(
                dateRange: StoreStatsConfigurationIntent.defaultDateRange,
                metrics: reordered
            )
        )

        // Then
        #expect(tile.isDefault == false)
    }

    @Test func storeInfo_tile_with_non_default_dateRange_is_not_default() {
        // Given
        let metrics = Array(StoreStatsConfigurationIntent.defaultMetrics.prefix(2))
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemSmall,
            configuration: .storeStats(
                dateRange: .lastWeek,
                metrics: metrics
            )
        )

        // Then
        #expect(tile.isDefault == false)
    }

    @Test func storeInfo_tile_with_subset_of_default_metrics_in_order_is_default() {
        // Given - only 2 metrics matching the first 2 of the default priority list
        let metrics = Array(StoreStatsConfigurationIntent.defaultMetrics.prefix(2))
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemSmall,
            configuration: .storeStats(
                dateRange: StoreStatsConfigurationIntent.defaultDateRange,
                metrics: metrics
            )
        )

        // Then
        #expect(tile.isDefault == true)
    }

    @Test func storeTrends_tile_with_default_dateRange_and_default_metrics_is_default() {
        // Given
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeTrendsWidgetKind,
            family: .accessoryRectangular,
            configuration: .storeStats(
                dateRange: StoreTrendsConfigurationIntent.defaultDateRange,
                metrics: StoreTrendsConfigurationIntent.defaultMetrics
            )
        )

        // Then
        #expect(tile.isDefault == true)
    }

    @Test func storeTrends_tile_with_non_default_metric_is_not_default() {
        // Given
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeTrendsWidgetKind,
            family: .accessoryRectangular,
            configuration: .storeStats(
                dateRange: StoreTrendsConfigurationIntent.defaultDateRange,
                metrics: [.orders]
            )
        )

        // Then
        #expect(tile.isDefault == false)
    }

    @Test func unconfigured_tile_reports_nil_for_isDefault() {
        // Given
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.appLinkWidgetKind,
            family: .accessoryCircular,
            configuration: .unconfigured
        )

        // Then
        #expect(tile.isDefault == nil)
    }

    @Test func storeInfo_tile_from_intent_uses_storeStats_configuration_intent() {
        // Given
        var intent = StoreStatsConfigurationIntent()
        intent.dateRange = .lastWeek
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
        #expect(tile.configuration == .storeStats(dateRange: .lastWeek, metrics: [.revenue, .orders, .itemsSold, .averageOrderValue]))
    }

    @Test func storeTrends_tile_from_intent_uses_storeTrends_configuration_intent() {
        // Given
        var intent = StoreTrendsConfigurationIntent()
        intent.dateRange = .lastMonth
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
        #expect(tile.configuration == .storeStats(dateRange: .lastMonth, metrics: [.revenue]))
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
            configuration: .storeStats(dateRange: .lastWeek, metrics: [.revenue, .orders])
        )

        // Then
        #expect(WidgetSnapshot(tiles: [tileA]) != WidgetSnapshot(tiles: [tileB]))
    }
}
