import XCTest
import Networking
@testable import Yosemite

final class PointOfSaleSearchPurchasableItemFetchStrategyTests: XCTestCase {
    private let siteID: Int64 = 123
    private let searchTerm = "test search"
    private let productsRemote = MockProductsRemote()
    private let variationsRemote = MockProductVariationsRemote()
    private let mockAnalytics = MockPOSSearchAnalyticsTracking()

    func test_fetchProducts_tracks_analytics_for_first_page() async throws {
        // Given
        let strategy = PointOfSaleSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            productsRemote: productsRemote,
            variationsRemote: variationsRemote,
            analytics: mockAnalytics
        )
        let expectedTotalItems = 10
        productsRemote.mockPagedProducts = .init(items: [], hasMorePages: true, totalItems: expectedTotalItems)

        // When
        _ = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        XCTAssertEqual(mockAnalytics.spyMillisecondsSinceRequestSent, 0) // We can't test exact timing
        XCTAssertEqual(mockAnalytics.spyTotalItems, expectedTotalItems)
    }

    func test_fetchProducts_does_not_track_analytics_for_subsequent_pages() async throws {
        // Given
        let strategy = PointOfSaleSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            productsRemote: productsRemote,
            variationsRemote: variationsRemote,
            analytics: mockAnalytics
        )
        productsRemote.mockPagedProducts = .init(items: [], hasMorePages: true, totalItems: 10)

        // When
        _ = try await strategy.fetchProducts(pageNumber: 2)

        // Then
        XCTAssertNil(mockAnalytics.spyMillisecondsSinceRequestSent)
        XCTAssertNil(mockAnalytics.spyTotalItems)
    }
}

// MARK: - Mocks

private final class MockProductsRemote: ProductsRemote {
    var mockPagedProducts: PagedItems<POSProduct>?

    override func searchProductsForPointOfSale(for siteID: Int64,
                                              query: String,
                                              productTypes: [ProductType],
                                              pageNumber: Int) async throws -> PagedItems<POSProduct> {
        return mockPagedProducts ?? .init(items: [], hasMorePages: false, totalItems: nil)
    }
}

private final class MockProductVariationsRemote: ProductVariationsRemote {
    override func loadVariationsForPointOfSale(for siteID: Int64,
                                              parentProductID: Int64,
                                              pageNumber: Int) async throws -> PagedItems<ProductVariation> {
        return .init(items: [], hasMorePages: false, totalItems: nil)
    }
}

private final class MockPOSSearchAnalyticsTracking: POSSearchAnalyticsTracking {
    private(set) var spyMillisecondsSinceRequestSent: Int?
    private(set) var spyTotalItems: Int?

    func trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int) {
        spyMillisecondsSinceRequestSent = millisecondsSinceRequestSent
        spyTotalItems = totalItems
    }
}