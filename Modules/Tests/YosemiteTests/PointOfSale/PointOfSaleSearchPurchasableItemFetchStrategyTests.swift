import Testing
import Networking
@testable import Yosemite

struct PointOfSaleSearchPurchasableItemFetchStrategyTests {
    private let siteID: Int64 = 123
    private let searchTerm = "test search"
    private let productsRemote = MockProductsRemote()
    private let variationsRemote = MockProductVariationsRemote()
    private let mockAnalytics = MockPOSItemFetchAnalyticsTracking()

    @Test func fetchProducts_tracks_analytics_for_first_page() async throws {
        // Given
        let strategy = PointOfSaleSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            productsRemote: productsRemote,
            variationsRemote: variationsRemote,
            analytics: mockAnalytics
        )
        let expectedTotalItems = 10
        productsRemote.whenSearchingProductsForPointOfSale(query: searchTerm,
                                                           thenReturn: .success(.init(items: [],
                                                                                      hasMorePages: true,
                                                                                      totalItems: expectedTotalItems)))

        // When
        _ = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(mockAnalytics.spyMillisecondsSinceRequestSent == 0) // We can't test exact timing
        #expect(mockAnalytics.spySearchTotalItems == expectedTotalItems)
    }

    @Test func fetchProducts_does_not_track_analytics_for_subsequent_pages() async throws {
        // Given
        let strategy = PointOfSaleSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            productsRemote: productsRemote,
            variationsRemote: variationsRemote,
            analytics: mockAnalytics
        )
        productsRemote.whenSearchingProductsForPointOfSale(query: searchTerm,
                                                           thenReturn: .success(.init(items: [],
                                                                                      hasMorePages: true,
                                                                                      totalItems: 10)))

        // When
        _ = try await strategy.fetchProducts(pageNumber: 2)

        // Then
        #expect(mockAnalytics.spyMillisecondsSinceRequestSent == nil)
        #expect(mockAnalytics.spyTotalItems == nil)
    }
}
