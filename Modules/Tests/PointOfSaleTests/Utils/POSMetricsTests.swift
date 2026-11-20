import Testing
import SwiftUI
@testable import PointOfSale

struct POSMetricsTests {
    @Test func test_metrics_when_regular_then_keeps_tablet_values() {
        // Given / When
        let metrics = POSMetrics.metrics(for: .regular)

        // Then
        #expect(metrics.spacing.medium == 16)
        #expect(metrics.padding.xxLarge == 40)
        #expect(metrics.productCardSize == 112)
    }

    @Test func test_metrics_when_compact_then_uses_phone_values() {
        // Given / When
        let metrics = POSMetrics.metrics(for: .compact)

        // Then
        #expect(metrics.spacing.medium == 12)
        #expect(metrics.padding.xxLarge == 24)
        #expect(metrics.productCardSize == 96)
    }

    @Test func test_posMetrics_environment_value_follows_layout_scale() {
        // Given
        var environment = EnvironmentValues()

        // When
        environment.posLayoutScale = .compact

        // Then
        #expect(environment.posMetrics == .compact)
    }
}
