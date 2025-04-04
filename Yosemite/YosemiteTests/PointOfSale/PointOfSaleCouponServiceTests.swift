import Testing
@testable import Yosemite
import class WooFoundation.CurrencySettings

struct PointOfSaleCouponServiceTests {
    private let sut: PointOfSaleCouponService
    private let couponStoreMethods: MockCouponStoreMethods
    private let settingStoreMethods: MockSettingStoreMethods
    private let storage: MockStorageManager

    init() {
        self.couponStoreMethods = MockCouponStoreMethods()
        self.settingStoreMethods = MockSettingStoreMethods()
        self.storage = MockStorageManager()
        self.sut = .init(siteID: 123,
                         currencySettings: CurrencySettings(),
                         couponStoreMethods: couponStoreMethods,
                         settingStoreMethods: settingStoreMethods,
                         storage: storage
        )
    }

    @Test func providePointOfSaleCoupons_when_one_coupon_in_store_then_one_coupon_returned() async throws {
        // Given
        let coupon = Coupon.fake().copy(siteID: 123, code: "coupon")
        storage.insertSampleCoupon(readOnlyCoupon: coupon)

        // When
        let coupons = try await sut.providePointOfSaleCoupons(pageNumber: 0)

        // Then
        #expect(coupons.items.count == 1)
    }

    @Test func providePointOfSaleCoupons_when_two_coupons_in_store_then_two_coupons_returned() async throws {
        // Given
        let coupon = Coupon.fake().copy(siteID: 123, couponID: 0, code: "coupon")
        storage.insertSampleCoupon(readOnlyCoupon: coupon)
        let coupon2 = Coupon.fake().copy(siteID: 123, couponID: 1, code: "coupon2")
        storage.insertSampleCoupon(readOnlyCoupon: coupon2)

        // When
        let coupons = try await sut.providePointOfSaleCoupons(pageNumber: 0)

        // Then
        #expect(coupons.items.count == 2)
    }

    @Test func providePointOfSaleCoupons_when_no_coupons_then_synchronize_called() async throws {
        try await _ = sut.providePointOfSaleCoupons(pageNumber: 0)

        #expect(couponStoreMethods.synchronizeCalled == true)
    }

    @available(iOS 17.0, *)
    @Test func providePointOfSaleCoupons_when_some_coupons_then_synchronize_called_later() async throws {
        // Given
        let coupon = Coupon.fake().copy(siteID: 123, code: "coupon")
        storage.insertSampleCoupon(readOnlyCoupon: coupon)

        try await confirmation(expectedCount: 1) { confirmation in
            couponStoreMethods.onSynchronizeCalled = {
                // Then
                confirmation()
            }

            // When
            try await _ = sut.providePointOfSaleCoupons(pageNumber: 0)
        }

    }
}
