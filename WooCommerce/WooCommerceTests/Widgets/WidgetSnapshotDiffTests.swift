import Testing
import WidgetKit
@testable import WooCommerce

struct WidgetSnapshotDiffTests {

    // MARK: - Helpers

    private static func storeStatsTile(
        family: WidgetFamily = .systemMedium,
        dateRange: StoreStatsWidgetDateRange,
        metrics: [StoreInfoMetricType]
    ) -> WidgetSnapshot.Tile {
        WidgetSnapshot.Tile(
            kind: WooConstants.storeInfoWidgetKind,
            family: family,
            configuration: .storeStats(dateRange: dateRange, metrics: metrics)
        )
    }

    private static func unconfiguredTile(family: WidgetFamily = .accessoryCircular) -> WidgetSnapshot.Tile {
        WidgetSnapshot.Tile(
            kind: WooConstants.appLinkWidgetKind,
            family: family,
            configuration: .unconfigured
        )
    }

    // MARK: - hasChanged

    @Test func hasChanged_is_false_for_identical_snapshots() {
        // Given
        let tile = Self.storeStatsTile(dateRange: .today, metrics: [.revenue, .orders])
        let snapshot = WidgetSnapshot(tiles: [tile])
        let diff = WidgetSnapshotDiff(previous: snapshot, current: snapshot)

        // Then
        #expect(diff.hasChanged == false)
    }

    @Test func hasChanged_is_true_when_metric_order_differs() {
        // Given
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue, .orders])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.orders, .revenue])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then
        #expect(diff.hasChanged)
    }

    // MARK: - changeType

    @Test func changeType_is_add_when_current_count_is_higher() {
        // Given
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue]),
            Self.storeStatsTile(family: .systemSmall, dateRange: .today, metrics: [.orders])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then
        #expect(diff.changeType == .add)
    }

    @Test func changeType_is_remove_when_current_count_is_lower() {
        // Given
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue]),
            Self.storeStatsTile(family: .systemSmall, dateRange: .today, metrics: [.orders])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then
        #expect(diff.changeType == .remove)
    }

    @Test func changeType_is_churn_when_counts_match_but_configs_differ() {
        // Given
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .last7Days, metrics: [.revenue])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then
        #expect(diff.changeType == .churn)
    }

    // MARK: - addedDateRanges / removedDateRanges

    @Test func addedDateRanges_contains_only_newly_used_ranges() {
        // Given - previous: today; current: today + last7Days (today still in use)
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue]),
            Self.storeStatsTile(family: .systemSmall, dateRange: .last7Days, metrics: [.orders])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then - today is shared so excluded; only last7Days is new
        #expect(diff.addedDateRanges == ["last7Days"])
        #expect(diff.removedDateRanges == [])
    }

    @Test func removedDateRanges_contains_only_no_longer_used_ranges() {
        // Given
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .last30Days, metrics: [.revenue])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then
        #expect(diff.addedDateRanges == ["today"])
        #expect(diff.removedDateRanges == ["last30Days"])
    }

    // MARK: - addedMetrics / removedMetrics

    @Test func addedMetrics_excludes_metrics_already_in_use_in_other_tiles() {
        // Given - revenue is in use across both snapshots even though tile changed
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue, .orders])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue, .visitors])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then - revenue stays in use; visitors is new; orders dropped out of use
        #expect(diff.addedMetrics == ["visitors"])
        #expect(diff.removedMetrics == ["orders"])
    }

    @Test func addedMetrics_is_empty_for_identical_metric_sets() {
        // Given - same metrics, different order; produces hasChanged but no metric set diff
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue, .orders])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.orders, .revenue])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then - reorder shows up only via hasChanged + churn; aggregate diff is empty
        #expect(diff.hasChanged)
        #expect(diff.changeType == .churn)
        #expect(diff.addedMetrics.isEmpty)
        #expect(diff.removedMetrics.isEmpty)
    }

    @Test func unconfigured_tiles_do_not_affect_metric_or_dateRange_diffs() {
        // Given
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(dateRange: .today, metrics: [.revenue]),
            Self.unconfiguredTile()
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then - tile count went up but no new metrics or dateRanges entered use
        #expect(diff.changeType == .add)
        #expect(diff.addedMetrics.isEmpty)
        #expect(diff.addedDateRanges.isEmpty)
    }

    // MARK: - addedWidgets / removedWidgets

    @Test func addedWidgets_uses_kind_family_combined_analytics_name() {
        // Given - previous: medium tile; current: medium + small tile
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .today, metrics: [.revenue])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .today, metrics: [.revenue]),
            Self.storeStatsTile(family: .systemSmall, dateRange: .today, metrics: [.orders])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then - `StoreInfoWidget-systemSmall` is the new kind:family combo
        #expect(diff.addedWidgets == ["StoreInfoWidget-systemSmall"])
        #expect(diff.removedWidgets == [])
    }

    @Test func removedWidgets_reports_disappeared_kind_family_combos() {
        // Given
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .today, metrics: [.revenue]),
            Self.storeStatsTile(family: .systemLarge, dateRange: .today, metrics: [.revenue])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .today, metrics: [.revenue])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then
        #expect(diff.addedWidgets == [])
        #expect(diff.removedWidgets == ["StoreInfoWidget-systemLarge"])
    }

    @Test func unconfigured_tiles_use_their_own_analytics_name_in_diff() {
        // Given - previous: storeInfo only; current: + appLink unconfigured
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .today, metrics: [.revenue])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .today, metrics: [.revenue]),
            Self.unconfiguredTile()
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then
        #expect(diff.addedWidgets == ["AppLinkWidget-accessoryCircular"])
        #expect(diff.removedWidgets == [])
    }

    @Test func metric_replacement_with_already_used_value_reduces_combined_set_by_one() {
        // Given - 2 tiles, combined metrics: {revenue, orders, visitors}
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .today, metrics: [.revenue, .orders]),
            Self.storeStatsTile(family: .systemSmall, dateRange: .today, metrics: [.orders, .visitors])
        ])
        // User changes tile A's first metric from `revenue` to `visitors`.
        // Combined now: {visitors, orders} — one less than before.
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .today, metrics: [.visitors, .orders]),
            Self.storeStatsTile(family: .systemSmall, dateRange: .today, metrics: [.orders, .visitors])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then
        #expect(diff.hasChanged)
        #expect(diff.changeType == .churn)
        #expect(diff.addedMetrics == [])
        #expect(diff.removedMetrics == ["revenue"])
        #expect(diff.addedDateRanges == [])
        #expect(diff.removedDateRanges == [])
    }

    @Test func same_kind_family_with_different_configs_is_not_a_widget_diff() {
        // Given - same medium kind:family but reconfigured contents
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .today, metrics: [.revenue])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemMedium, dateRange: .last7Days, metrics: [.visitors])
        ])

        // When
        let diff = WidgetSnapshotDiff(previous: previous, current: current)

        // Then - kind:family combo unchanged so widgets diff is empty; metric/dateRange diff non-empty
        #expect(diff.addedWidgets == [])
        #expect(diff.removedWidgets == [])
        #expect(diff.addedDateRanges == ["last7Days"])
        #expect(diff.removedDateRanges == ["today"])
    }
}
