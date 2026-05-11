import Testing
import Foundation
import WidgetKit
@testable import WooCommerce

struct WidgetSnapshotPersistenceTests {

    private static func makeIsolatedDefaults(file: StaticString = #file, line: UInt = #line) -> UserDefaults {
        let suite = "WidgetSnapshotPersistenceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func roundtrips_storeStats_tile_through_userDefaults() {
        // Given
        let defaults = Self.makeIsolatedDefaults()
        var persistence = UserDefaultsWidgetSnapshotPersistence(userDefaults: defaults)
        let original = WidgetSnapshot(tiles: [
            WidgetSnapshot.Tile(
                kind: WooConstants.storeInfoWidgetKind,
                family: .systemMedium,
                configuration: .storeStats(dateRange: .last7Days, metrics: [.orders, .revenue])
            )
        ])

        // When
        persistence.lastSnapshot = original
        let recovered = persistence.lastSnapshot

        // Then
        #expect(recovered == original)
    }

    @Test func roundtrips_unconfigured_tile_through_userDefaults() {
        // Given
        let defaults = Self.makeIsolatedDefaults()
        var persistence = UserDefaultsWidgetSnapshotPersistence(userDefaults: defaults)
        let original = WidgetSnapshot(tiles: [
            WidgetSnapshot.Tile(
                kind: WooConstants.appLinkWidgetKind,
                family: .accessoryCircular,
                configuration: .unconfigured
            )
        ])

        // When
        persistence.lastSnapshot = original
        let recovered = persistence.lastSnapshot

        // Then
        #expect(recovered == original)
    }

    @Test func returns_nil_when_no_snapshot_persisted() {
        // Given
        let defaults = Self.makeIsolatedDefaults()
        let persistence = UserDefaultsWidgetSnapshotPersistence(userDefaults: defaults)

        // Then
        #expect(persistence.lastSnapshot == nil)
    }

    @Test func setting_nil_clears_persisted_snapshot() {
        // Given
        let defaults = Self.makeIsolatedDefaults()
        var persistence = UserDefaultsWidgetSnapshotPersistence(userDefaults: defaults)
        persistence.lastSnapshot = WidgetSnapshot(tiles: [
            WidgetSnapshot.Tile(
                kind: WooConstants.storeInfoWidgetKind,
                family: .systemMedium,
                configuration: .storeStats(dateRange: .today, metrics: [.revenue])
            )
        ])

        // When
        persistence.lastSnapshot = nil

        // Then
        #expect(persistence.lastSnapshot == nil)
    }

    @Test func roundtrips_mixed_snapshot_preserving_order_and_metrics() {
        // Given - mixed tiles with non-default metric order
        let defaults = Self.makeIsolatedDefaults()
        var persistence = UserDefaultsWidgetSnapshotPersistence(userDefaults: defaults)
        let original = WidgetSnapshot(tiles: [
            WidgetSnapshot.Tile(
                kind: WooConstants.storeInfoWidgetKind,
                family: .systemSmall,
                configuration: .storeStats(dateRange: .today, metrics: [.orders, .revenue])
            ),
            WidgetSnapshot.Tile(
                kind: WooConstants.appLinkWidgetKind,
                family: .accessoryCircular,
                configuration: .unconfigured
            ),
            WidgetSnapshot.Tile(
                kind: WooConstants.storeInfoWidgetKind,
                family: .systemLarge,
                configuration: .storeStats(
                    dateRange: .last30Days,
                    metrics: [.visitors, .conversion, .averageOrderValue]
                )
            )
        ])

        // When
        persistence.lastSnapshot = original
        let recovered = persistence.lastSnapshot

        // Then - tile order, metric order, and dateRange all preserved
        #expect(recovered == original)
    }
}
