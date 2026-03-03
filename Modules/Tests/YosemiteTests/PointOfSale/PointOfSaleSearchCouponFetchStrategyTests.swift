import Foundation
import Testing
import YosemiteTestHelpers
@testable import Yosemite
import class WooFoundation.CurrencySettings

struct PointOfSaleSearchCouponFetchStrategyTests {
    private let sut: PointOfSaleSearchCouponFetchStrategy
    private let couponStoreMethods: MockCouponStoreMethods
    private let storage: MockStorageManager
    private let sampleSiteID: Int64 = 123
    private let searchTerm = "test"
    private let mockAnalytics: MockPOSItemFetchAnalyticsTracking

    init() {
        self.couponStoreMethods = MockCouponStoreMethods()
        self.storage = MockStorageManager()
        self.mockAnalytics = MockPOSItemFetchAnalyticsTracking()
        self.sut = .init(
            siteID: sampleSiteID,
            currencySettings: CurrencySettings(),
            storage: storage,
            couponStoreMethods: couponStoreMethods,
            searchTerm: searchTerm,
            analytics: mockAnalytics
        )
    }

    @Test func fetchLocalCoupons_always_returns_empty_array() async throws {
        // Given
        let coupon = Coupon.fake().copy(siteID: sampleSiteID, code: "coupon")
        storage.insertSampleCoupon(readOnlyCoupon: coupon)

        // When
        let coupons = try await sut.fetchLocalCoupons()

        // Then
        #expect(coupons.isEmpty)
    }

    @Test func fetchCoupons_when_no_results_then_returns_empty_array() async throws {
        // When
        let result = try await sut.fetchCoupons(pageNumber: 1)

        // Then
        #expect(result.items.isEmpty)
        #expect(!result.hasMorePages)
    }

    @Test func fetchCoupons_when_search_succeeds_then_returns_results() async throws {
        // Given
        let coupon1 = Coupon.fake().copy(siteID: sampleSiteID, code: "test_coupon_1")
        let coupon2 = Coupon.fake().copy(siteID: sampleSiteID, code: "test_coupon_2")
        storage.insertSampleCoupon(readOnlyCoupon: coupon1)
        storage.insertSampleCoupon(readOnlyCoupon: coupon2)
        storage.insertSampleCouponSearchResult(keyword: searchTerm, coupons: [coupon1, coupon2])

        // When
        let result = try await sut.fetchCoupons(pageNumber: 1)

        // Then
        #expect(result.items.count == 2)
        #expect(!result.hasMorePages)
    }

    @Test func fetchCoupons_when_search_fails_then_throws_couponsLoadingError() async throws {
        // Given
        let error = NSError(domain: "test", code: 0)
        couponStoreMethods.errorToThrow = error

        // When
        do {
            _ = try await sut.fetchCoupons(pageNumber: 1)
        } catch {
            // Then
            let expectedError = error as? PointOfSaleCouponServiceError
            #expect(expectedError == .couponsLoadingError(underlyingError: error))
        }
    }

    @Test func fetchCoupons_when_full_page_then_hasMorePages_is_true() async throws {
        // Given
        // Insert enough coupons to fill a page
        var coupons: [Coupon] = []
        for i in 0..<PointOfSaleDefaultCouponFetchStrategy.Constants.defaultPageSize {
            let coupon = Coupon.fake().copy(siteID: sampleSiteID, code: "test_coupon_\(i)")
            storage.insertSampleCoupon(readOnlyCoupon: coupon)
            coupons.append(coupon)
        }
        storage.insertSampleCouponSearchResult(keyword: searchTerm, coupons: coupons)

        // When
        let result = try await sut.fetchCoupons(pageNumber: 1)

        // Then
        #expect(result.items.count == PointOfSaleDefaultCouponFetchStrategy.Constants.defaultPageSize)
        #expect(result.hasMorePages)
    }

    @Test func fetchCoupons_when_not_full_page_then_hasMorePages_is_false() async throws {
        // Given
        // Insert less coupons than page size
        var coupons: [Coupon] = []
        for i in 0..<PointOfSaleDefaultCouponFetchStrategy.Constants.defaultPageSize - 1 {
            let coupon = Coupon.fake().copy(siteID: sampleSiteID, code: "test_coupon_\(i)")
            storage.insertSampleCoupon(readOnlyCoupon: coupon)
            coupons.append(coupon)
        }
        storage.insertSampleCouponSearchResult(keyword: searchTerm, coupons: coupons)

        // When
        let result = try await sut.fetchCoupons(pageNumber: 1)

        // Then
        #expect(result.items.count == PointOfSaleDefaultCouponFetchStrategy.Constants.defaultPageSize - 1)
        #expect(!result.hasMorePages)
    }

    @Test func fetchCoupons_tracks_analytics_for_first_page() async throws {
        // Given
        let coupon1 = Coupon.fake().copy(siteID: sampleSiteID, code: "test_coupon_1")
        let coupon2 = Coupon.fake().copy(siteID: sampleSiteID, code: "test_coupon_2")
        storage.insertSampleCoupon(readOnlyCoupon: coupon1)
        storage.insertSampleCoupon(readOnlyCoupon: coupon2)
        storage.insertSampleCouponSearchResult(keyword: searchTerm, coupons: [coupon1, coupon2])

        // When
        _ = try await sut.fetchCoupons(pageNumber: 1)

        // Then
        #expect(mockAnalytics.spyMillisecondsSinceRequestSent != nil)
        #expect(mockAnalytics.spySearchTotalItems == 2)
    }

    @Test func fetchCoupons_does_not_track_analytics_for_subsequent_pages() async throws {
        // Given
        let coupon1 = Coupon.fake().copy(siteID: sampleSiteID, code: "test_coupon_1")
        let coupon2 = Coupon.fake().copy(siteID: sampleSiteID, code: "test_coupon_2")
        storage.insertSampleCoupon(readOnlyCoupon: coupon1)
        storage.insertSampleCoupon(readOnlyCoupon: coupon2)
        storage.insertSampleCouponSearchResult(keyword: searchTerm, coupons: [coupon1, coupon2])

        // When
        _ = try await sut.fetchCoupons(pageNumber: 2)

        // Then
        #expect(mockAnalytics.spyMillisecondsSinceRequestSent == nil)
        #expect(mockAnalytics.spyTotalItems == nil)
    }
}
