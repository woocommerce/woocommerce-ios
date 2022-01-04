import Foundation
import Networking

final class MockCouponsRemote: CouponsRemoteProtocol {
    // MARK: - Spy properties
    var didCallLoadAllCoupons = false
    var spyLoadAllCouponsSiteID: Int64?
    var spyLoadAllCouponsPageNumber: Int?
    var spyLoadAllCouponsPageSize: Int?

    var didCallDeleteCoupon = false
    var spyDeleteCouponSiteID: Int64?
    var spyDeleteCouponWithID: Int64?

    // MARK: - Stub responses
    var resultForLoadAllCoupons: Result<[Coupon], Error>?

    // MARK: - CouponsRemoteProtocol conformance
    func loadAllCoupons(for siteID: Int64,
                        pageNumber: Int,
                        pageSize: Int,
                        completion: @escaping (Result<[Coupon], Error>) -> ()) {
        didCallLoadAllCoupons = true
        spyLoadAllCouponsSiteID = siteID
        spyLoadAllCouponsPageNumber = pageNumber
        spyLoadAllCouponsPageSize = pageSize
        guard let result = resultForLoadAllCoupons else { return }
        completion(result)
    }

    func deleteCoupon(for siteID: Int64,
                      couponID: Int64,
                      completion: @escaping (Result<Coupon, Error>) -> Void) {
        didCallDeleteCoupon = true
        spyDeleteCouponSiteID = siteID
        spyDeleteCouponWithID = couponID
    }
}
