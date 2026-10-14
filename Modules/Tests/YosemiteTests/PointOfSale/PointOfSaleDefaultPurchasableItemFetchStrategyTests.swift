import XCTest
import Fakes
@testable import Yosemite

@MainActor
final class PointOfSaleDefaultPurchasableItemFetchStrategyTests: XCTestCase {
    private let siteID: Int64 = 123
    private let productsRemote = MockProductsRemote()
    private let variationsRemote = MockProductVariationsRemote()
    private let mockAnalytics = MockPOSItemFetchAnalyticsTracking()
    private var sut: PointOfSaleDefaultPurchasableItemFetchStrategy!
    private var milliseconds = 0

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        sut = PointOfSaleDefaultPurchasableItemFetchStrategy(
            siteID: siteID,
            productsRemote: productsRemote,
            variationsRemote: variationsRemote,
            analytics: mockAnalytics,
            monotonicMilliseconds: { self.milliseconds }
        )
    }

    @MainActor
    override func tearDown() async throws {
        productsRemote.onLoadProductsForPointOfSale = nil
        sut = nil
        try await super.tearDown()
    }

    func test_fetchProducts_tracks_analytics_for_first_page() async throws {
        // Given
        let totalItems = 42
        productsRemote.whenLoadingProductsForPointOfSale(siteID: siteID, thenReturn: .success(.init(items: [], hasMorePages: false, totalItems: totalItems)))

        // When
        _ = try await sut.fetchProducts(pageNumber: 1)

        // Then
        XCTAssertEqual(mockAnalytics.spyTotalItems, totalItems)
        XCTAssertEqual(mockAnalytics.spyReturnedItemsCount, 0)
        XCTAssertEqual(mockAnalytics.spyItemsFetchMilliseconds, 0)
    }

    func test_fetch_products_when_remote_completes_then_measures_only_request_and_response_count() async throws {
        // Given
        let products = (1...7).map { POSProduct.fake().copy(productID: Int64($0)) }
        productsRemote.whenLoadingProductsForPointOfSale(siteID: siteID,
                                                         thenReturn: .success(.init(items: products, hasMorePages: true, totalItems: 42)))
        productsRemote.onLoadProductsForPointOfSale = {
            XCTAssertNil(self.mockAnalytics.spyTotalItems)
            self.milliseconds += 123
        }
        milliseconds = 5_000 // Time before the request must not be included.

        // When
        let result = try await sut.fetchProducts(pageNumber: 1)
        milliseconds += 1_000 // Later processing must not change the recorded request time.

        // Then
        XCTAssertEqual(result.items, products)
        XCTAssertEqual(mockAnalytics.spyTotalItems, 42)
        XCTAssertEqual(mockAnalytics.spyReturnedItemsCount, 7)
        XCTAssertEqual(mockAnalytics.spyItemsFetchMilliseconds, 123)
    }

    func test_fetch_products_when_next_request_follows_idle_then_starts_new_timer() async throws {
        // Given
        productsRemote.whenLoadingProductsForPointOfSale(siteID: siteID,
                                                         thenReturn: .success(.init(items: [], hasMorePages: false, totalItems: 0)))
        productsRemote.onLoadProductsForPointOfSale = { self.milliseconds += 123 }
        _ = try await sut.fetchProducts(pageNumber: 1)
        milliseconds = 20_000

        // When
        _ = try await sut.fetchProducts(pageNumber: 1)

        // Then
        XCTAssertEqual(mockAnalytics.spyItemsFetchMilliseconds, 123)
        XCTAssertEqual(mockAnalytics.spyReturnedItemsCount, 0)
    }

    func test_fetch_products_when_request_fails_then_does_not_track_success() async {
        // Given
        productsRemote.whenLoadingProductsForPointOfSale(siteID: siteID,
                                                         thenReturn: .failure(NSError(domain: "test", code: 1)))
        productsRemote.onLoadProductsForPointOfSale = { self.milliseconds += 123 }

        // When
        do {
            _ = try await sut.fetchProducts(pageNumber: 1)
            XCTFail("Expected the remote error")
        } catch {
            // Then
            XCTAssertNil(mockAnalytics.spyTotalItems)
            XCTAssertNil(mockAnalytics.spyReturnedItemsCount)
            XCTAssertNil(mockAnalytics.spyItemsFetchMilliseconds)
        }
    }

    func test_fetchProducts_does_not_track_analytics_for_subsequent_pages() async throws {
        // Given
        let totalItems = 42
        productsRemote.whenLoadingProductsForPointOfSale(siteID: siteID, thenReturn: .success(.init(items: [], hasMorePages: false, totalItems: totalItems)))

        // When
        _ = try await sut.fetchProducts(pageNumber: 2)

        // Then
        XCTAssertNil(mockAnalytics.spyTotalItems)
        XCTAssertNil(mockAnalytics.spyReturnedItemsCount)
        XCTAssertNil(mockAnalytics.spyItemsFetchMilliseconds)
    }

    func test_fetch_products_when_in_flight_request_is_cancelled_then_does_not_track_success() async {
        // Given
        productsRemote.whenLoadingProductsForPointOfSale(siteID: siteID, thenReturn: .failure(CancellationError()))
        var cancelRequest: (() -> Void)?
        productsRemote.onLoadProductsForPointOfSale = {
            cancelRequest?()
            XCTAssertTrue(Task.isCancelled)
            self.milliseconds += 123
        }

        // When
        let request = Task {
            do {
                _ = try await self.sut.fetchProducts(pageNumber: 1)
                XCTFail("Expected cancellation before a remote result")
            } catch {
                XCTAssertTrue(error is CancellationError)
            }
        }
        cancelRequest = { request.cancel() }
        await request.value

        // Then
        XCTAssertTrue(request.isCancelled)
        XCTAssertNil(mockAnalytics.spyTotalItems)
        XCTAssertNil(mockAnalytics.spyReturnedItemsCount)
        XCTAssertNil(mockAnalytics.spyItemsFetchMilliseconds)
    }
}
