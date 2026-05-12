@testable import WooCommerce
import Foundation
import Testing

struct WidgetReportsURLTests {

    @Test func url_whenBuilt_thenUsesAnalyticsHostAndPath() throws {
        // Given / When
        let url = try #require(WidgetReportsURL.url(for: .revenue, range: .today))

        // Then
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "https")
        #expect(components.host == "woocommerce.com")
        #expect(components.path == "/mobile/analytics")
    }

    @Test func url_whenBuilt_thenIncludesMetricRawValueAsQueryParameter() throws {
        // Given / When
        let url = try #require(WidgetReportsURL.url(for: .averageOrderValue, range: .weekToDate))

        // Then
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let metricItem = components.queryItems?.first(where: { $0.name == "metric" })
        #expect(metricItem?.value == "averageOrderValue")
    }

    @Test func url_whenBuilt_thenIncludesRangeRawValueAsQueryParameter() throws {
        // Given / When
        let url = try #require(WidgetReportsURL.url(for: .conversion, range: .monthToDate))

        // Then
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let rangeItem = components.queryItems?.first(where: { $0.name == "range" })
        #expect(rangeItem?.value == "monthToDate")
    }

    @Test func url_whenAllRangesBuilt_thenAllRoundTripCleanly() throws {
        // Given
        let allRanges: [StoreStatsWidgetDateRange] = [.today, .yesterday, .lastWeek, .lastMonth, .weekToDate, .monthToDate]

        // When / Then
        for range in allRanges {
            let url = try #require(WidgetReportsURL.url(for: .orders, range: range))
            let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let rangeItem = components.queryItems?.first(where: { $0.name == "range" })
            #expect(rangeItem?.value == range.rawValue, "Range \(range) failed to round-trip")
        }
    }
}
