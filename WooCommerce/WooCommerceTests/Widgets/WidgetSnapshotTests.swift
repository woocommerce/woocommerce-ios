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

    @Test func systemMedium_keeps_correct_metric_slot_count() {
        #expect(StoreStatsConfigurationIntent.metricsSlotCounts[.systemMedium] == 4)
    }

    @Test func systemLarge_keeps_correct_metric_slot_count() {
        #expect(StoreStatsConfigurationIntent.metricsSlotCounts[.systemLarge] == 7)
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
