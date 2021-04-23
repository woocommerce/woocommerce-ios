import Foundation
import Networking

final class MockCouponsRemote: CouponsRemoteProtocol {
    // MARK: - Spy properties
    var didCallLoadAllCoupons = false
    var spyLoadAllCouponsSiteID: Int64?
    var spyLoadAllCouponsPageNumber: Int?
    var spyLoadAllCouponsPageSize: Int?

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
}
