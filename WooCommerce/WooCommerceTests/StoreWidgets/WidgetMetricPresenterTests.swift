@testable import WooCommerce
import Foundation
import Testing
@testable import class WooFoundation.CurrencySettings

struct WidgetMetricPresenterTests {

    // MARK: - tapURL suppression

    @Test func tapURL_whenValueIsUnavailable_thenReturnsNil() {
        // Given
        let metric = StoreInfoMetric(type: .visitors, value: .unavailable)
        let presenter = WidgetMetricPresenter(metric: metric, dateRange: .today)

        // When / Then
        #expect(presenter.tapURL == nil)
    }

    @Test func tapURL_whenDateRangeIsNil_thenReturnsNil() {
        // Given
        let metric = StoreInfoMetric(type: .revenue, value: .currency(100, CurrencySettings()))
        let presenter = WidgetMetricPresenter(metric: metric, dateRange: nil)

        // When / Then
        #expect(presenter.tapURL == nil)
    }

    @Test func tapURL_whenValueAndRangeProvided_thenBuildsURL() throws {
        // Given
        let metric = StoreInfoMetric(type: .orders, value: .count(23))
        let presenter = WidgetMetricPresenter(metric: metric, dateRange: .lastWeek)

        // When
        let url = try #require(presenter.tapURL)

        // Then
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.first(where: { $0.name == "metric" })?.value == "orders")
        #expect(components.queryItems?.first(where: { $0.name == "range" })?.value == "lastWeek")
    }

    // MARK: - Forwarding

    @Test func presenter_forwardsTitleAndFormattedValue_fromUnderlyingMetric() {
        // Given
        let metric = StoreInfoMetric(type: .revenue, value: .currency(100, CurrencySettings()))
        let presenter = WidgetMetricPresenter(metric: metric, dateRange: .today)

        // When / Then
        #expect(presenter.title == metric.title)
        #expect(presenter.formattedValue == metric.formattedValue)
        #expect(presenter.trend == metric.trend)
    }
}
