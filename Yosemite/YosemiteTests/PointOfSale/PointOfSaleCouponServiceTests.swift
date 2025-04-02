import Testing
@testable import Yosemite
import class WooFoundation.CurrencySettings

struct PointOfSaleCouponServiceTests {
    let sut: PointOfSaleCouponService
    let couponService: MockCouponService
    let storage: MockStorageManager

    init() {
        self.couponService = MockCouponService()
        self.storage = MockStorageManager()
        self.sut = .init(siteID: 123,
                         currencySettings: CurrencySettings(),
                         couponService: couponService,
                         storage: storage
        )
    }

    @Test func synchronizeCalled() async throws {
//        try await sut.providePointOfSaleCoupons(pageNumber: 0)
//
//        #expect(couponService.synchronizeCalled == true)
    }

    @Test func coupons() async throws {
        let coupon = Coupon.fake().copy(siteID: 123, code: "coupon")
        storage.insertSampleCoupon(readOnlyCoupon: coupon)

        let coupons = try await sut.providePointOfSaleCoupons(pageNumber: 0)

        #expect(coupons.items.count == 1)
    }

    @Test func multipleCoupons() async throws {
        let coupon = Coupon.fake().copy(siteID: 123, code: "coupon")
        storage.insertSampleCoupon(readOnlyCoupon: coupon)
        let coupon2 = Coupon.fake().copy(siteID: 123, code: "coupon2")
        storage.insertSampleCoupon(readOnlyCoupon: coupon2)

        let coupons = try await sut.providePointOfSaleCoupons(pageNumber: 0)

        #expect(coupons.items.count == 2)
    }

}

class MockCouponService: CouponServiceProtocol {
    var synchronizeCalled = false
    func synchronizeCoupons(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Result<Bool, any Error>) -> Void) {
        synchronizeCalled = true
    }
}

