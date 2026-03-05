import Foundation
import Testing
import YosemiteTestHelpers
@testable import Yosemite
import class WooFoundation.CurrencySettings

struct PointOfSaleDefaultCouponFetchStrategyTests {
    private let sut: PointOfSaleDefaultCouponFetchStrategy
    private let couponStoreMethods: MockCouponStoreMethods
    private let storage: MockStorageManager
    private let sampleSiteID: Int64 = 123

    init() {
        self.couponStoreMethods = MockCouponStoreMethods()
        self.storage = MockStorageManager()
        self.sut = .init(
            siteID: sampleSiteID,
            currencySettings: CurrencySettings(),
            storage: storage,
            couponStoreMethods: couponStoreMethods
        )
    }

    @Test func fetchLocalCoupons_when_zero_coupons_then_returns_empty_array() async throws {
        // Given, When
        let coupons = try await sut.fetchLocalCoupons()

        // Then
        #expect(coupons.isEmpty)
    }

    @Test func fetchLocalCoupons_when_some_coupons_then_returns_coupons() async throws {
        // Given
        let coupon1 = Coupon.fake().copy(siteID: sampleSiteID, code: "coupon_123")
        let coupon2 = Coupon.fake().copy(siteID: sampleSiteID, code: "coupon_456")
        let expectedCoupons = 2

        storage.insertSampleCoupon(readOnlyCoupon: coupon1)
        storage.insertSampleCoupon(readOnlyCoupon: coupon2)

        // When
        let coupons = try await sut.fetchLocalCoupons()

        // Then
        #expect(coupons.count == expectedCoupons)
    }

    @Test func fetchCoupons_when_no_coupons_then_synchronize_called() async throws {
        // When
        _ = try await sut.fetchCoupons(pageNumber: 0)

        // Then
        #expect(couponStoreMethods.synchronizeCalled)
    }

    @Test func fetchCoupons_when_some_coupons_then_synchronize_called() async throws {
        // Given
        let coupon = Coupon.fake().copy(siteID: sampleSiteID, code: "coupon")
        storage.insertSampleCoupon(readOnlyCoupon: coupon)

        // When
        _ = try await sut.fetchCoupons(pageNumber: 0)

        // Then
        #expect(couponStoreMethods.synchronizeCalled)
    }

    @Test func fetchCoupons_when_sync_fails_then_throws_couponsLoadingError() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 0)
        couponStoreMethods.errorToThrow = expectedError

        // When
        do {
            _ = try await sut.fetchCoupons(pageNumber: 0)
        } catch {
            // Then
            #expect(expectedError == error as NSError)
        }
    }

    @Test func fetchCoupons_when_have_expired_coupons_then_returns_all_coupons() async throws {
        // Given
        let now = Date()
        let noExpiration: Date? = nil
        let expiresTomorrow: Date = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? Date()
        let expiredYesterday: Date = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? Date()

        let validCouponWithNoExpiration = Coupon.fake().copy(siteID: sampleSiteID, code: "ok_coupon_forever", dateExpires: noExpiration)
        storage.insertSampleCoupon(readOnlyCoupon: validCouponWithNoExpiration)

        let validCouponExpiresTomorrow = Coupon.fake().copy(siteID: sampleSiteID, code: "ok_coupon_for_some_time", dateExpires: expiresTomorrow)
        storage.insertSampleCoupon(readOnlyCoupon: validCouponExpiresTomorrow)

        let expiredCoupon = Coupon.fake().copy(siteID: sampleSiteID, code: "expired_coupon", dateExpires: expiredYesterday)
        storage.insertSampleCoupon(readOnlyCoupon: expiredCoupon)

        // When
        let result = try await sut.fetchCoupons(pageNumber: 0)

        // Then
        #expect(result.items.count == 3)
    }
}
