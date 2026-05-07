import Testing
import WidgetKit
@testable import WooCommerce

struct WidgetSnapshotAnalyticsTests {

    // MARK: - Counts

    @Test func empty_snapshot_produces_zero_counts_and_empty_aggregates() {
        // Given
        let snapshot = WidgetSnapshot(tiles: [])

        // When
        let props = snapshot.analyticsProperties

        // Then
        #expect(props["widget_count"] == "0")
        #expect(props["widget_customized_count"] == "0")
        #expect(props["widget_default_count"] == "0")
        #expect(props["info_widget_date_ranges_in_use"]?.isEmpty == true)
        #expect(props["info_widget_metrics_in_use"]?.isEmpty == true)
    }

    @Test func single_default_storeStats_tile_counts_as_default() {
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
        let snapshot = WidgetSnapshot(tiles: [tile])

        // When
        let props = snapshot.analyticsProperties

        // Then
        #expect(props["widget_count"] == "1")
        #expect(props["widget_default_count"] == "1")
        #expect(props["widget_customized_count"] == "0")
    }

    @Test func single_customized_storeStats_tile_counts_as_customized() {
        // Given
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemSmall,
            configuration: .storeStats(dateRange: .last7Days, metrics: [.orders, .revenue])
        )
        let snapshot = WidgetSnapshot(tiles: [tile])

        // When
        let props = snapshot.analyticsProperties

        // Then
        #expect(props["widget_count"] == "1")
        #expect(props["widget_default_count"] == "0")
        #expect(props["widget_customized_count"] == "1")
    }

    @Test func unconfigured_tile_is_excluded_from_default_and_customized_counts() {
        // Given
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.appLinkWidgetKind,
            family: .accessoryCircular,
            configuration: .unconfigured
        )
        let snapshot = WidgetSnapshot(tiles: [tile])

        // When
        let props = snapshot.analyticsProperties

        // Then
        #expect(props["widget_count"] == "1")
        #expect(props["widget_default_count"] == "0")
        #expect(props["widget_customized_count"] == "0")
    }

    @Test func mixed_snapshot_aggregates_counts_correctly() {
        // Given
        let defaultTile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(
                dateRange: StoreStatsConfigurationIntent.defaultDateRange,
                metrics: Array(StoreStatsConfigurationIntent.defaultMetrics.prefix(4))
            )
        )
        let customizedTile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemSmall,
            configuration: .storeStats(dateRange: .last30Days, metrics: [.orders, .revenue])
        )
        let unconfiguredTile = WidgetSnapshot.Tile(
            kind: WooConstants.appLinkWidgetKind,
            family: .accessoryCircular,
            configuration: .unconfigured
        )
        let snapshot = WidgetSnapshot(tiles: [defaultTile, customizedTile, unconfiguredTile])

        // When
        let props = snapshot.analyticsProperties

        // Then
        #expect(props["widget_count"] == "3")
        #expect(props["widget_default_count"] == "1")
        #expect(props["widget_customized_count"] == "1")
    }

    // MARK: - info_widget_date_ranges_in_use

    @Test func single_storeStats_tile_reports_its_date_range() {
        // Given
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(dateRange: .today, metrics: [.revenue])
        )
        let snapshot = WidgetSnapshot(tiles: [tile])

        // When
        let props = snapshot.analyticsProperties

        // Then
        #expect(props["info_widget_date_ranges_in_use"] == "today")
    }

    @Test func multiple_tiles_report_date_ranges_with_repetitions_sorted() {
        // Given - three tiles, two share the same dateRange
        let tileA = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemSmall,
            configuration: .storeStats(dateRange: .today, metrics: [.revenue])
        )
        let tileB = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(dateRange: .last7Days, metrics: [.revenue])
        )
        let tileC = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemLarge,
            configuration: .storeStats(dateRange: .today, metrics: [.revenue])
        )
        let snapshot = WidgetSnapshot(tiles: [tileA, tileB, tileC])

        // When
        let props = snapshot.analyticsProperties

        // Then - multiset CSV preserves repetitions, alphabetically sorted
        #expect(props["info_widget_date_ranges_in_use"] == "last7Days,today,today")
    }

    @Test func unconfigured_tile_excluded_from_date_ranges() {
        // Given
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.appLinkWidgetKind,
            family: .accessoryCircular,
            configuration: .unconfigured
        )
        let snapshot = WidgetSnapshot(tiles: [tile])

        // When
        let props = snapshot.analyticsProperties

        // Then
        #expect(props["info_widget_date_ranges_in_use"]?.isEmpty == true)
    }

    // MARK: - info_widget_metrics_in_use

    @Test func single_storeStats_tile_reports_its_metrics_alphabetized() {
        // Given - metrics in user-defined order
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(dateRange: .today, metrics: [.revenue, .orders])
        )
        let snapshot = WidgetSnapshot(tiles: [tile])

        // When
        let props = snapshot.analyticsProperties

        // Then - aggregate is alphabetized (loses order on purpose)
        #expect(props["info_widget_metrics_in_use"] == "orders,revenue")
    }

    @Test func multiple_tiles_combine_metrics_with_repetitions() {
        // Given - tiles with overlapping metrics
        let tileA = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemSmall,
            configuration: .storeStats(dateRange: .today, metrics: [.revenue, .orders])
        )
        let tileB = WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: .systemMedium,
            configuration: .storeStats(dateRange: .last7Days, metrics: [.orders, .visitors])
        )
        let snapshot = WidgetSnapshot(tiles: [tileA, tileB])

        // When
        let props = snapshot.analyticsProperties

        // Then - multiset CSV: orders appears twice, sorted alphabetically
        #expect(props["info_widget_metrics_in_use"] == "orders,orders,revenue,visitors")
    }

    @Test func unconfigured_tile_excluded_from_metrics_combined() {
        // Given
        let tile = WidgetSnapshot.Tile(
            kind: WooConstants.appLinkWidgetKind,
            family: .accessoryCircular,
            configuration: .unconfigured
        )
        let snapshot = WidgetSnapshot(tiles: [tile])

        // When
        let props = snapshot.analyticsProperties

        // Then
        #expect(props["info_widget_metrics_in_use"]?.isEmpty == true)
    }
}
