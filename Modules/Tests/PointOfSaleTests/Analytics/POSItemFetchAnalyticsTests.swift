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
    @Test func test_items_fetch_when_remote_request_succeeds_then_reports_duration_and_response_count() throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let sut = POSItemFetchAnalytics(itemType: .product, analytics: mockAnalytics)

        // When
        sut.trackItemsFetchComplete(totalItems: 42, returnedItemsCount: 7, millisecondsSinceRequestSent: 123)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsFetched.rawValue)
        #expect(event.properties["total_items"] as? String == "42")
        #expect(event.properties["sync_strategy"] as? String == "remote")
        #expect(event.properties["returned_items_count"] as? Int == 7)
        #expect(event.properties["milliseconds_since_request_sent"] as? Int == 123)
        #expect(event.properties["source"] as? String == "product")
        #expect(event.properties["pos_timing_version"] == nil)
    }

    @Test(arguments: [0, -1])
    func test_items_fetch_when_empty_then_keeps_zero_count_and_only_nonnegative_duration(milliseconds: Int) throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let sut = POSItemFetchAnalytics(itemType: .product, analytics: mockAnalytics)

        // When
        sut.trackItemsFetchComplete(totalItems: 0, returnedItemsCount: 0, millisecondsSinceRequestSent: milliseconds)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.properties["returned_items_count"] as? Int == 0)
        #expect(event.properties["total_items"] as? String == "0")
        #expect(event.properties["sync_strategy"] as? String == "remote")
        #expect(event.properties["milliseconds_since_request_sent"] as? Int == (milliseconds < 0 ? nil : 0))
    }

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
