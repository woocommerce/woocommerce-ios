import Testing
import WidgetKit
import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider
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

    @Test func first_observation_persists_baseline_and_does_not_emit_event() {
        // Given
        let stub = StubWidgetSnapshotPersistence()
        let analytics = RecordingAnalytics()
        let tracker = WidgetSetupChangeTracker(persistence: stub)
        let snapshot = WidgetSnapshot(tiles: [Self.storeStatsTile()])

        // When
        tracker.track(currentSnapshot: snapshot, analytics: analytics)

        // Then
        #expect(analytics.receivedEvents.contains(WooAnalyticsStat.widgetSetupChanged.rawValue) == false)
        #expect(stub.lastSnapshot == snapshot)
    }

    @Test func unchanged_snapshot_is_a_noop() {
        // Given
        let snapshot = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let stub = StubWidgetSnapshotPersistence()
        stub.lastSnapshot = snapshot
        let analytics = RecordingAnalytics()
        let tracker = WidgetSetupChangeTracker(persistence: stub)

        // When
        tracker.track(currentSnapshot: snapshot, analytics: analytics)

        // Then
        #expect(analytics.receivedEvents.contains(WooAnalyticsStat.widgetSetupChanged.rawValue) == false)
    }

    @Test func changed_snapshot_fires_widgetSetupChanged_with_correct_properties() {
        // Given
        let previous = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(),
            Self.storeStatsTile(family: .systemSmall, dateRange: .last7Days, metrics: [.visitors])
        ])
        let stub = StubWidgetSnapshotPersistence()
        stub.lastSnapshot = previous
        let analytics = RecordingAnalytics()
        let tracker = WidgetSetupChangeTracker(persistence: stub)

        // When
        tracker.track(currentSnapshot: current, analytics: analytics)

        // Then
        let eventName = WooAnalyticsStat.widgetSetupChanged.rawValue
        let index = analytics.receivedEvents.firstIndex(of: eventName)
        #expect(index != nil)
        guard let idx = index else { return }
        let props = analytics.receivedProperties[idx]
        #expect(props["previous_widget_count"] as? Int == 1)
        #expect(props["current_widget_count"] as? Int == 2)
        #expect(props["change_type"] as? String == "add")
        #expect(props["info_widget_date_ranges_added"] as? String == "last7Days")
        #expect(props["info_widget_date_ranges_removed"] == nil)
        #expect(props["info_widget_metrics_added"] as? String == "visitors")
        #expect(props["info_widget_metrics_removed"] == nil)
        #expect(props["widgets_added"] as? String == "StoreInfoWidget-systemSmall")
        #expect(props["widgets_removed"] == nil)
    }

    @Test func changed_snapshot_persists_new_state_after_emitting() {
        // Given
        let previous = WidgetSnapshot(tiles: [Self.storeStatsTile()])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(family: .systemSmall, dateRange: .last30Days, metrics: [.orders])
        ])
        let stub = StubWidgetSnapshotPersistence()
        stub.lastSnapshot = previous
        let tracker = WidgetSetupChangeTracker(persistence: stub)

        // When
        tracker.track(currentSnapshot: current, analytics: RecordingAnalytics())

        // Then
        #expect(stub.lastSnapshot == current)
    }

    @Test func metric_reorder_only_fires_churn_with_empty_diff_dimensions() {
        // Given
        let previous = WidgetSnapshot(tiles: [
            Self.storeStatsTile(metrics: [.revenue, .orders])
        ])
        let current = WidgetSnapshot(tiles: [
            Self.storeStatsTile(metrics: [.orders, .revenue])
        ])
        let stub = StubWidgetSnapshotPersistence()
        stub.lastSnapshot = previous
        let analytics = RecordingAnalytics()
        let tracker = WidgetSetupChangeTracker(persistence: stub)

        // When
        tracker.track(currentSnapshot: current, analytics: analytics)

        // Then
        let eventName = WooAnalyticsStat.widgetSetupChanged.rawValue
        let index = analytics.receivedEvents.firstIndex(of: eventName)
        #expect(index != nil)
        guard let idx = index else { return }
        let props = analytics.receivedProperties[idx]
        #expect(props["change_type"] as? String == "churn")
        #expect(props["info_widget_metrics_added"] == nil)
        #expect(props["info_widget_metrics_removed"] == nil)
    }
}

// MARK: - Test Doubles

private final class StubWidgetSnapshotPersistence: WidgetSnapshotPersisting {
    var lastSnapshot: WidgetSnapshot?
}

/// Lightweight `Analytics` stub that records every `track` call without any global side effects.
/// We avoid constructing a real `WooAnalytics` here because its `init` calls `WPAnalytics.register(...)`,
/// which mutates global state and races / double-frees when Swift Testing runs tests in parallel.
private final class RecordingAnalytics: Analytics {
    private(set) var receivedEvents: [String] = []
    private(set) var receivedProperties: [[AnyHashable: Any]] = []
    var userHasOptedIn: Bool = true

    var analyticsProvider: AnalyticsProvider {
        fatalError("RecordingAnalytics has no underlying provider")
    }

    func initialize() {}
    func refreshUserData() {}
    func setUserHasOptedOut(_ optedOut: Bool) {}

    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        receivedEvents.append(eventName)
        receivedProperties.append(properties ?? [:])
    }
}
