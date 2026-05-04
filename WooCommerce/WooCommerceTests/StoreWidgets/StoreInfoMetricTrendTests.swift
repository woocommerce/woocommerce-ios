@testable import WooCommerce
import Foundation
import Testing

/// Exercises the trend computation reachable through `StoreInfoMetric.trend`. The actual
/// math lives on a `private extension StoreInfoMetricValue` in `MetricPresentable.swift`,
/// so this suite drives it through the `MetricPresentable` conformance — the same path
/// `MetricCellView` uses.
///
struct StoreInfoMetricTrendTests {

    @Test func trend_whenPreviousValueIsMissing_thenReturnsNil() {
        // Given
        let metric = StoreInfoMetric(type: .orders, value: .count(20), previousValue: nil)

        // When / Then
        #expect(metric.trend == nil)
    }

    @Test func trend_whenPreviousValueIsUnavailable_thenReturnsNil() {
        // Given
        let metric = StoreInfoMetric(type: .visitors, value: .count(20), previousValue: .unavailable)

        // When / Then
        #expect(metric.trend == nil)
    }

    @Test func trend_whenCurrentValueIsUnavailable_thenReturnsNil() {
        // Given
        let metric = StoreInfoMetric(type: .visitors, value: .unavailable, previousValue: .count(10))

        // When / Then
        #expect(metric.trend == nil)
    }

    @Test func trend_whenDeltaIsZero_thenReturnsNil() {
        // Given
        let metric = StoreInfoMetric(type: .orders, value: .count(20), previousValue: .count(20))

        // When / Then
        #expect(metric.trend == nil)
    }

    @Test func trend_whenCurrentExceedsPrevious_thenReturnsUpDirection() {
        // Given — 20 → 30 = +50 %
        let metric = StoreInfoMetric(type: .orders, value: .count(30), previousValue: .count(20))

        // When
        let trend = metric.trend

        // Then
        #expect(trend?.direction == .up)
    }

    @Test func trend_whenCurrentBelowPrevious_thenReturnsDownDirection() {
        // Given — 20 → 10 = -50 %
        let metric = StoreInfoMetric(type: .orders, value: .count(10), previousValue: .count(20))

        // When
        let trend = metric.trend

        // Then
        #expect(trend?.direction == .down)
    }

    @Test func trend_whenPreviousIsZero_thenTreatsAsHundredPercent() {
        // Given — 0 → 5 has no meaningful ratio, surface as 100 % rather than `nil`
        let metric = StoreInfoMetric(type: .orders, value: .count(5), previousValue: .count(0))

        // When
        let trend = metric.trend

        // Then
        #expect(trend?.direction == .up)
        #expect(trend?.formattedPercentage == "100%")
    }

    @Test func trend_whenCurrencyValuesDecrease_thenReturnsDownDirection() {
        // Given — $200 → $150 = -25 %
        let metric = StoreInfoMetric(
            type: .revenue,
            value: .currency(150, nil),
            previousValue: .currency(200, nil)
        )

        // When
        let trend = metric.trend

        // Then
        #expect(trend?.direction == .down)
    }

    @Test func trend_whenPercentageValuesIncrease_thenReturnsUpDirection() {
        // Given — 10 % → 20 % = +100 %
        let metric = StoreInfoMetric(
            type: .conversion,
            value: .percentage(0.20),
            previousValue: .percentage(0.10)
        )

        // When
        let trend = metric.trend

        // Then
        #expect(trend?.direction == .up)
    }
}
