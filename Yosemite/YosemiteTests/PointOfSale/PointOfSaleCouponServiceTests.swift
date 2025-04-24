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

    @Test func provideLocalPointOfSaleCoupons_when_disabled_then_expects_couponsDisabled_error() async throws {
        // Given
        settingStoreMethods.couponsEnabled = false

        // When
        await confirmation(expectedCount: 1) { confirmation in
            settingStoreMethods.retrieveCouponSetting(siteID: sampleSiteID, onCompletion: { result in
                switch result {
                case let .success(isEnabled):
                    #expect(isEnabled == false)
                    confirmation()
                case .failure:
                    break
                }
            })

            do {
                // Then
                _ = try await sut.provideLocalPointOfSaleCoupons()
            } catch {
                let expectedError = error as? PointOfSaleCouponServiceError
                #expect(expectedError == .couponsDisabled)
            }
        }
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

    @Test func provideLocalPointOfSaleCoupons_when_storage_has_enabled_setting_then_returns_coupons() async throws {
        // Given
        let setting = SiteSetting.fake().copy(siteID: sampleSiteID,
                                            settingID: "woocommerce_enable_coupons",
                                            value: "yes")
        storage.insertSampleSiteSetting(readOnlySiteSetting: setting)
        let coupon = Coupon.fake().copy(siteID: sampleSiteID, code: "coupon_123")
        storage.insertSampleCoupon(readOnlyCoupon: coupon)

        // When
        let coupons = try await sut.provideLocalPointOfSaleCoupons()

        // Then
        #expect(coupons.count == 1)
        #expect(settingStoreMethods.retrieveCouponSettingCalled == false)
    }

    @Test func provideLocalPointOfSaleCoupons_when_storage_has_disabled_setting_then_checks_remote() async throws {
        // Given
        let setting = SiteSetting.fake().copy(siteID: sampleSiteID,
                                            settingID: "woocommerce_enable_coupons",
                                            value: "no")
        storage.insertSampleSiteSetting(readOnlySiteSetting: setting)
        settingStoreMethods.couponsEnabled = true

        // When
        await confirmation(expectedCount: 1) { confirmation in
            settingStoreMethods.retrieveCouponSetting(siteID: sampleSiteID) { _ in
                confirmation()
            }
            _ = try? await sut.provideLocalPointOfSaleCoupons()
        }

        // Then
        #expect(settingStoreMethods.retrieveCouponSettingCalled == true)
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

    @Test func providePointOfSaleCoupons_when_have_expired_coupons_then_provides_all_coupons() async throws {
        // Given
        let now = Date()
        let noExpiration: Date? = nil
        let expiresTomorrow: Date = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? Date()
        let expiredYesterday: Date = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? Date()

        let validCouponWithNoExpiration = Coupon.fake().copy(siteID: 123, code: "ok_coupon_forever", dateExpires: noExpiration)
        storage.insertSampleCoupon(readOnlyCoupon: validCouponWithNoExpiration)

        let validCouponExpiresTomorrow = Coupon.fake().copy(siteID: 123, code: "ok_coupon_for_some_time", dateExpires: expiresTomorrow)
        storage.insertSampleCoupon(readOnlyCoupon: validCouponExpiresTomorrow)

        let expiredCoupon = Coupon.fake().copy(siteID: 123, code: "expired_coupon", dateExpires: expiredYesterday)
        storage.insertSampleCoupon(readOnlyCoupon: expiredCoupon)

        // When
        let coupons = try await sut.providePointOfSaleCoupons(pageNumber: 0)

        // Then
        #expect(coupons.items.count == 3)
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

    @Test func providePointOfSaleCoupons_when_sync_fails_and_coupons_enabled_then_throws_couponsLoadingError() async throws {
        // Given
        settingStoreMethods.couponsEnabled = true
        couponStoreMethods.shouldFailSync = true

        // When
        do {
            _ = try await sut.providePointOfSaleCoupons(pageNumber: 0)
        } catch {
            // Then
            let expectedError = error as? PointOfSaleCouponServiceError
            #expect(expectedError == .couponsLoadingError)
        }
    }

    @Test func providePointOfSaleCoupons_when_sync_fails_and_coupons_disabled_then_throws_couponsDisabled() async throws {
        // Given
        settingStoreMethods.couponsEnabled = false
        couponStoreMethods.shouldFailSync = true

        // When
        do {
            _ = try await sut.providePointOfSaleCoupons(pageNumber: 0)
        } catch {
            // Then
            let expectedError = error as? PointOfSaleCouponServiceError
            #expect(expectedError == .couponsDisabled)
        }
    }
}
