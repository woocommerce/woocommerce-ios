import XCTest
@testable import Yosemite

final class PointOfSaleDefaultPurchasableItemFetchStrategyTests: XCTestCase {
    private let siteID: Int64 = 123
    private let productsRemote = MockProductsRemote()
    private let variationsRemote = MockProductVariationsRemote()
    private let mockAnalytics = MockPOSItemFetchAnalyticsTracking()
    private var sut: PointOfSaleDefaultPurchasableItemFetchStrategy!

    override func setUp() {
        super.setUp()
        sut = PointOfSaleDefaultPurchasableItemFetchStrategy(
            siteID: siteID,
            productsRemote: productsRemote,
            variationsRemote: variationsRemote,
            analytics: mockAnalytics
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_fetchProducts_tracks_analytics_for_first_page() async throws {
        // Given
        let totalItems = 42
        productsRemote.whenLoadingProductsForPointOfSale(siteID: siteID, thenReturn: .success(.init(items: [], hasMorePages: false, totalItems: totalItems)))

        // When
        _ = try await sut.fetchProducts(pageNumber: 1)

        // Then
        XCTAssertEqual(mockAnalytics.spyTotalItems, totalItems)
    }

    func test_fetchProducts_does_not_track_analytics_for_subsequent_pages() async throws {
        // Given
        let totalItems = 42
        productsRemote.whenLoadingProductsForPointOfSale(siteID: siteID, thenReturn: .success(.init(items: [], hasMorePages: false, totalItems: totalItems)))

        // When
        _ = try await sut.fetchProducts(pageNumber: 2)

        // Then
        XCTAssertNil(mockAnalytics.spyTotalItems)
    }
}
