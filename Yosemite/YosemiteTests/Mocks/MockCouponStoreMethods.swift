import Foundation
@testable import Yosemite
import Networking

final class MockCouponStoreMethods: CouponStoreMethodsProtocol {
    var synchronizeCalled = false
    var deleteCalled = false
    var updateCalled = false
    var createCalled = false
    var loadReportCalled = false
    var loadMostActiveCalled = false
    var searchCalled = false
    var retrieveCalled = false
    var loadCouponsCalled = false
    var validateCalled = false
    var errorToThrow: NSError?

    var onSynchronizeCalled: () -> Void = {}

    func synchronizeCoupons(siteID: Int64,
                            pageNumber: Int,
                            pageSize: Int) async throws -> Bool {
        synchronizeCalled = true
        onSynchronizeCalled()
        if let errorToThrow {
            throw errorToThrow
        }
        return true
    }

    func synchronizeCoupons(siteID: Int64,
                            pageNumber: Int,
                            pageSize: Int,
                            onCompletion: @escaping (Result<Bool, any Error>) -> Void) {
        synchronizeCalled = true
        if let errorToThrow {
            onCompletion(.failure(errorToThrow))
        } else {
            onCompletion(.success(true))
        }
        onSynchronizeCalled()
    }

    func deleteCoupon(siteID: Int64,
                      couponID: Int64,
                      onCompletion: @escaping (Result<Void, any Error>) -> Void) {
        deleteCalled = true
        onCompletion(.success(()))
    }

    func updateCoupon(_ coupon: Yosemite.Coupon,
                      siteTimezone: TimeZone?,
                      onCompletion: @escaping (Result<Yosemite.Coupon, any Error>) -> Void) {
        updateCalled = true
        onCompletion(.success(coupon))
    }

    func createCoupon(_ coupon: Yosemite.Coupon,
                      siteTimezone: TimeZone?,
                      onCompletion: @escaping (Result<Yosemite.Coupon, any Error>) -> Void) {
        createCalled = true
        onCompletion(.success(coupon))
    }

    func loadCouponReport(siteID: Int64,
                          couponID: Int64,
                          startDate: Date,
                          onCompletion: @escaping (Result<Yosemite.CouponReport, any Error>) -> Void) {
        loadReportCalled = true
    }

    func loadMostActiveCoupons(siteID: Int64,
                               numberOfCouponsToLoad: Int,
                               timeRange: Yosemite.StatsTimeRangeV4,
                               siteTimezone: TimeZone,
                               onCompletion: @escaping (Result<[Yosemite.CouponReport], any Error>) -> Void) {
        loadMostActiveCalled = true
    }

    func searchCoupons(siteID: Int64,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int,
                       onCompletion: @escaping (Result<Void, any Error>) -> Void) {
        searchCalled = true
        onCompletion(.success(()))
    }

    func searchCoupons(siteID: Int64,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int) async throws {
        searchCalled = true
    }

    func retrieveCoupon(siteID: Int64,
                        couponID: Int64,
                        onCompletion: @escaping (Result<Yosemite.Coupon, any Error>) -> Void) {
        retrieveCalled = true
    }

    func loadCoupons(siteID: Int64,
                     couponIDs: [Int64],
                     onCompletion: @escaping (Result<[Yosemite.Coupon], any Error>) -> Void) {
        loadCouponsCalled = true
    }

    func validateCouponCode(code: String,
                           siteID: Int64,
                           onCompletion: @escaping (Result<Bool, any Error>) -> Void) {
        validateCalled = true
        onCompletion(.success(false))
    }
}
