import Testing
@testable import Yosemite
import class WooFoundation.CurrencySettings

struct PointOfSaleCouponServiceTests {
    private let sut: PointOfSaleCouponService
    private let couponStoreMethods: MockCouponStoreMethods
    private let settingStoreMethods: MockSettingStoreMethods
    private let storage: MockStorageManager
    
    private let sampleSiteID: Int64 = 123

    init() {
        self.couponStoreMethods = MockCouponStoreMethods()
        self.settingStoreMethods = MockSettingStoreMethods()
        self.storage = MockStorageManager()
        self.sut = .init(siteID: sampleSiteID,
                         currencySettings: CurrencySettings(),
                         couponStoreMethods: couponStoreMethods,
                         settingStoreMethods: settingStoreMethods,
                         storage: storage
        )
    }
    
    @Test func provideLocalPointOfSaleCoupons_when_zero_coupons_in_local_storage_then_provides_zero_coupons() async throws {
        // Given, When
        let coupons = try await sut.provideLocalPointOfSaleCoupons()
        
        // Then
        #expect(coupons.isEmpty)
    }
    
    @Test func provideLocalPointOfSaleCoupons_when_some_coupons_in_local_storage_then_provides_some_coupons() async throws {
        // Given
        let coupon1 = Coupon.fake().copy(siteID: sampleSiteID, code: "coupon_123")
        let coupon2 = Coupon.fake().copy(siteID: sampleSiteID, code: "coupon_456")
        let expectedCoupons = 2
        
        storage.insertSampleCoupon(readOnlyCoupon: coupon1)
        storage.insertSampleCoupon(readOnlyCoupon: coupon2)
        
        // When
        let coupons = try await sut.provideLocalPointOfSaleCoupons()
        
        // Then
        #expect(coupons.count == expectedCoupons)
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
