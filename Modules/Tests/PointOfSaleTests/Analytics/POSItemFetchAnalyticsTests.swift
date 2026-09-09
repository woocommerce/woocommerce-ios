import Testing
import Foundation
import enum WooFoundationCore.WooAnalyticsStat
import enum Yosemite.POSItemType
import enum Yosemite.POSSearchMethod
import enum Yosemite.POSSearchSource
@testable import PointOfSale

private enum AnalyticsKeys {
    static let searchMethod = "search_method"
    static let resultsCount = "results_count"
    static let millisecondsSinceRequestSent = "milliseconds_since_request_sent"
}

struct POSItemFetchAnalyticsTests {
    @Test func trackSearchRemoteResultsFetchComplete_tracks_remote_search_method() throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let sut = POSItemFetchAnalytics(itemType: .product, analytics: mockAnalytics)

        // When
        sut.trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: 250, totalItems: 7)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleSearchRemoteResultsFetched.rawValue)
        #expect(event.properties[AnalyticsKeys.searchMethod] as? String == POSSearchMethod.remote.rawValue)
        #expect(event.properties[AnalyticsKeys.resultsCount] as? String == "7")
        #expect(event.properties[AnalyticsKeys.millisecondsSinceRequestSent] as? String == "250")
    }

    @Test func trackSearchLocalResultsFetchComplete_keeps_the_local_search_method() throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let sut = POSItemFetchAnalytics(itemType: .product, analytics: mockAnalytics)

        // When
        sut.trackSearchLocalResultsFetchComplete(millisecondsSinceRequestSent: 12,
                                                 totalItems: 3,
                                                 searchMethod: .fts,
                                                 source: .purchasableItems)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleSearchResultsFetched.rawValue)
        #expect(event.properties[AnalyticsKeys.searchMethod] as? String == POSSearchMethod.fts.rawValue)
    }
}
