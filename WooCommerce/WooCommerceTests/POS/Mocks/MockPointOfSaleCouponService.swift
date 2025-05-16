import Foundation
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSaleCouponServiceProtocol
import enum Yosemite.POSItem
import struct Yosemite.POSCoupon
import struct Yosemite.PagedItems
import struct Yosemite.POSVariableParentProduct
import enum Yosemite.PointOfSaleCouponServiceError
import protocol Yosemite.PointOfSaleCouponFetchStrategy

final class MockPointOfSaleCouponService: PointOfSaleCouponServiceProtocol {
    var shouldReturnZeroItems = false
    var errorToThrow: PointOfSaleCouponServiceError?
    var shouldSimulateTwoPages = false
    var shouldSimulateMorePages = false

    func provideLocalPointOfSaleCoupons(fetchStrategy: PointOfSaleCouponFetchStrategy) async throws -> [Yosemite.POSItem] {
        []
    }

    func providePointOfSaleCoupons(pageNumber: Int, fetchStrategy: PointOfSaleCouponFetchStrategy) async throws -> PagedItems<POSItem> {
        if let error = errorToThrow {
            throw error
        }
        if shouldReturnZeroItems {
            return .init(items: [], hasMorePages: false, totalItems: nil)
        }
        if shouldSimulateTwoPages {
            return pageNumber > 1 ?
                .init(items: Self.makeSecondPageCoupons(), hasMorePages: shouldSimulateMorePages, totalItems: nil):
                .init(items: Self.makeInitialCoupons(), hasMorePages: shouldSimulateTwoPages, totalItems: nil)
        }
        return .init(items: Self.makeInitialCoupons(), hasMorePages: false, totalItems: nil)
    }

    static func makeInitialCoupons() -> [POSItem] {
        let coupon1 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84A")) ?? UUID(), code: "VALID1"))
        let coupon2 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84B")) ?? UUID(), code: "VALID2"))
        let coupon3 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84C")) ?? UUID(), code: "VALID3"))
        return [coupon1, coupon2, coupon3]
    }

    static func makeSecondPageCoupons() -> [POSItem] {
        let coupon4 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84D")) ?? UUID(), code: "VALID4"))
        let coupon5 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84E")) ?? UUID(), code: "VALID5"))
        let coupon6 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84F")) ?? UUID(), code: "VALID6"))
        return [coupon4, coupon5, coupon6]
    }

    func enableCoupons() async throws {
        if let error = errorToThrow {
            throw error
        }
    }
}
