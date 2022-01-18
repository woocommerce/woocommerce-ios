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

    var didCallUpdateCoupon = false
    var spyUpdateCoupon: Coupon?

    var didCallCreateCoupon = false
    var spyCreateCoupon: Coupon?

    var didCallLoadCouponReport = false
    var spyLoadCouponReportSiteID: Int64?
    var spyLoadCouponReportCouponID: Int64?

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

    func updateCoupon(_ coupon: Coupon, completion: @escaping (Result<Coupon, Error>) -> Void) {
        didCallUpdateCoupon = true
        spyUpdateCoupon = coupon
    }

    func createCoupon(_ coupon: Coupon, completion: @escaping (Result<Coupon, Error>) -> Void) {
        didCallCreateCoupon = true
        spyCreateCoupon = coupon
    }

    func loadCouponReport(for siteID: Int64, couponID: Int64, completion: @escaping (Result<CouponReport, Error>) -> Void) {
        didCallLoadAllCoupons = true
        spyLoadCouponReportSiteID = siteID
        spyLoadCouponReportCouponID = couponID
    }
}
