import Testing
import WidgetKit
@testable import WooCommerce

struct WidgetSnapshotDiffAnalyticsTests {

    private static func storeStatsTile(
        family: WidgetFamily = .systemMedium,
        dateRange: StoreStatsWidgetDateRange = .today,
        metrics: [StoreInfoMetricType] = [.revenue, .orders]
    ) -> WidgetSnapshot.Tile {
        WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: family,
            configuration: .storeStats(dateRange: dateRange, metrics: metrics)
        )
    }

    @Test func always_present_keys_are_set_on_any_change() {
        // Given
        let previous = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(),
            Self.storeStatsTile(family: .systemSmall, dateRange: .last7Days, metrics: [.visitors])
        ])
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // When
        let props = diff.analyticsProperties

        // Then
        #expect(props["widget_setup_change_type"] == "add")
        #expect(props["previous_widget_count"] == "1")
    }

    @Test func empty_added_or_removed_csvs_are_omitted() {
        // Given - same single tile, only metric order differs (churn with no aggregate diff)
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(metrics: [.revenue, .orders])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(metrics: [.orders, .revenue])
        ])
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // When
        let props = diff.analyticsProperties

        // Then
        #expect(props["widget_setup_change_type"] == "churn")
        #expect(props["info_widget_metrics_added"] == nil)
        #expect(props["info_widget_metrics_removed"] == nil)
        #expect(props["info_widget_date_ranges_added"] == nil)
        #expect(props["info_widget_date_ranges_removed"] == nil)
        #expect(props["widgets_added"] == nil)
        #expect(props["widgets_removed"] == nil)
    }

    @Test func added_aggregates_are_populated_when_non_empty() {
        // Given
        let previous = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(),
            Self.storeStatsTile(family: .systemSmall, dateRange: .last7Days, metrics: [.visitors])
        ])
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // When
        let props = diff.analyticsProperties

        // Then
        #expect(props["info_widget_date_ranges_added"] == "last7Days")
        #expect(props["info_widget_metrics_added"] == "visitors")
        #expect(props["widgets_added"] == "StoreInfoWidget-systemSmall")
    }

    @Test func removed_aggregates_are_populated_when_tiles_disappear() {
        // Given
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(),
            Self.storeStatsTile(family: .systemSmall, dateRange: .last7Days, metrics: [.visitors])
        ])
        let current = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // When
        let props = diff.analyticsProperties

        // Then
        #expect(props["widget_setup_change_type"] == "remove")
        #expect(props["info_widget_date_ranges_removed"] == "last7Days")
        #expect(props["info_widget_metrics_removed"] == "visitors")
        #expect(props["widgets_removed"] == "StoreInfoWidget-systemSmall")
    }
}
