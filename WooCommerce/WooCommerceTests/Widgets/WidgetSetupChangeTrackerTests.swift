import Testing
import WidgetKit
@testable import WooCommerce

struct WidgetSetupChangeTrackerTests {

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

    @Test func first_observation_persists_baseline_and_returns_nil() {
        // Given
        let stub = StubWidgetSnapshotPersistence()
        let tracker = WidgetSetupChangeTracker(persistence: stub)
        let snapshot = WidgetSnapshot(tiles: [Self.storeStatsTile()])

        // When
        let diff = tracker.evaluate(currentSnapshot: snapshot)

        // Then
        #expect(diff == nil)
        #expect(stub.lastSnapshot == snapshot)
    }

    @Test func unchanged_snapshot_returns_nil() {
        // Given
        let snapshot = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let stub = StubWidgetSnapshotPersistence()
        stub.lastSnapshot = snapshot
        let tracker = WidgetSetupChangeTracker(persistence: stub)

        // When
        let diff = tracker.evaluate(currentSnapshot: snapshot)

        // Then
        #expect(diff == nil)
    }

    @Test func changed_snapshot_returns_diff_against_previous_baseline() {
        // Given
        let previous = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(),
            Self.storeStatsTile(family: .systemSmall, dateRange: .last7Days, metrics: [.visitors])
        ])
        let stub = StubWidgetSnapshotPersistence()
        stub.lastSnapshot = previous
        let tracker = WidgetSetupChangeTracker(persistence: stub)

        // When
        let diff = tracker.evaluate(currentSnapshot: current)

        // Then
        #expect(diff != nil)
        #expect(diff?.previous == previous)
        #expect(diff?.current == current)
    }

    @Test func changed_snapshot_persists_new_state_after_returning_diff() {
        // Given
        let previous = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemSmall, dateRange: .last30Days, metrics: [.orders])
        ])
        let stub = StubWidgetSnapshotPersistence()
        stub.lastSnapshot = previous
        let tracker = WidgetSetupChangeTracker(persistence: stub)

        // When
        _ = tracker.evaluate(currentSnapshot: current)

        // Then
        #expect(stub.lastSnapshot == current)
    }

    @Test func unchanged_snapshot_does_not_overwrite_persisted_baseline() {
        // Given
        let snapshot = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let stub = StubWidgetSnapshotPersistence()
        stub.lastSnapshot = snapshot
        let tracker = WidgetSetupChangeTracker(persistence: stub)

        // When
        _ = tracker.evaluate(currentSnapshot: snapshot)

        // Then
        #expect(stub.lastSnapshot == snapshot)
    }
}

// MARK: - Test Doubles

private final class StubWidgetSnapshotPersistence: WidgetSnapshotPersisting {
    var lastSnapshot: WidgetSnapshot?
}
