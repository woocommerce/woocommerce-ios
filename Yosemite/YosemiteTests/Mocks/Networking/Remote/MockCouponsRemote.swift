import Foundation
import Networking

final class MockCouponsRemote: CouponsRemoteProtocol {

    // MARK: - Spy properties
    var didCallLoadAllCoupons = false
    var spyLoadAllCouponsSiteID: Int64?
    var spyLoadAllCouponsPageNumber: Int?
    var spyLoadAllCouponsPageSize: Int?

    var didCallSearchCoupons = false
    var spySearchCouponsSiteID: Int64?
    var spySearchCouponsPageNumber: Int?
    var spySearchCouponsPageSize: Int?
    var spySearchCouponsKeyword: String?

    var didCallRetrieveCoupon = false
    var spyRetrieveSiteID: Int64?
    var spyRetrieveCouponID: Int64?

    var didCallDeleteCoupon = false
    var spyDeleteCouponSiteID: Int64?
    var spyDeleteCouponWithID: Int64?

    var didCallUpdateCoupon = false
    var spyUpdateCoupon: Coupon?

    var didCallCreateCoupon = false
    var spyCreateCoupon: Coupon?

    var didCallLoadCouponReport = false
    var spyLoadCouponReportDate: Date?
    var spyLoadCouponReportSiteID: Int64?
    var spyLoadCouponReportCouponID: Int64?

    var didCallLoadMostActiveCoupons = false
    var spyLoadMostActiveCouponsSiteID: Int64?
    var spyLoadMostActiveCouponsStartDate: Date?
    var spyLoadMostActiveCouponsEndDate: Date?

    // MARK: - Stub responses
    var resultForLoadAllCoupons: Result<[Coupon], Error>?
    var resultForSearchCoupons: Result<[Coupon], Error>?

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

    func searchCoupons(for siteID: Int64,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int,
                       completion: @escaping (Result<[Coupon], Error>) -> ()) {
        didCallSearchCoupons = true
        spySearchCouponsKeyword = keyword
        spySearchCouponsSiteID = siteID
        spySearchCouponsPageSize = pageSize
        spySearchCouponsPageNumber = pageNumber
        guard let result = resultForSearchCoupons else { return }
        completion(result)
    }

    func deleteCoupon(for siteID: Int64,
                      couponID: Int64,
                      completion: @escaping (Result<Coupon, Error>) -> Void) {
        didCallDeleteCoupon = true
        spyDeleteCouponSiteID = siteID
        spyDeleteCouponWithID = couponID
    }

    func updateCoupon(_ coupon: Coupon,
                      siteTimezone: TimeZone?,
                      completion: @escaping (Result<Coupon, Error>) -> Void) {
        didCallUpdateCoupon = true
        spyUpdateCoupon = coupon
    }

    func createCoupon(_ coupon: Coupon,
                      siteTimezone: TimeZone?,
                      completion: @escaping (Result<Coupon, Error>) -> Void) {
        didCallCreateCoupon = true
        spyCreateCoupon = coupon
    }

    func loadCouponReport(for siteID: Int64, couponID: Int64, from startDate: Date, completion: @escaping (Result<CouponReport, Error>) -> Void) {
        didCallLoadCouponReport = true
        spyLoadCouponReportDate = startDate
        spyLoadCouponReportSiteID = siteID
        spyLoadCouponReportCouponID = couponID
    }

    func retrieveCoupon(for siteID: Int64, couponID: Int64, completion: @escaping (Result<Coupon, Error>) -> Void) {
        didCallRetrieveCoupon = true
        spyRetrieveSiteID = siteID
        spyRetrieveCouponID = couponID
    }

    func loadMostActiveCoupons(for siteID: Int64,
                               from startDate: Date,
                               to endDate: Date,
                               completion: @escaping (Result<[CouponReport], Error>) -> Void) {
        didCallLoadMostActiveCoupons = true
        spyLoadMostActiveCouponsSiteID = siteID
        spyLoadMostActiveCouponsStartDate = startDate
        spyLoadMostActiveCouponsEndDate = endDate
    }
}
