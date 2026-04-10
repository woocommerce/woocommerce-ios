import Foundation
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSaleCouponServiceProtocol
import enum Yosemite.POSItem
import struct Yosemite.POSCoupon
import struct Yosemite.POSItemIdentifier
import struct Yosemite.PagedItems
import struct Yosemite.POSVariableParentProduct
import enum Yosemite.PointOfSaleCouponServiceError
import protocol Yosemite.PointOfSaleCouponFetchStrategy

final class MockPointOfSaleCouponService: PointOfSaleCouponServiceProtocol {
    var shouldReturnZeroItems = false
    var errorToThrow: PointOfSaleCouponServiceError?
    var localErrorToThrow: PointOfSaleCouponServiceError?
    var shouldSimulateTwoPages = false
    var shouldSimulateMorePages = false

    func provideLocalPointOfSaleCoupons(fetchStrategy: PointOfSaleCouponFetchStrategy) async throws -> [Yosemite.POSItem] {
        if let error = localErrorToThrow {
            throw error
        }
        return []
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
        let coupon1 = POSItem.coupon(POSCoupon(id: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "VALID1"))
        let coupon2 = POSItem.coupon(POSCoupon(id: POSItemIdentifier(underlyingType: .coupon, itemID: 2), code: "VALID2"))
        let coupon3 = POSItem.coupon(POSCoupon(id: POSItemIdentifier(underlyingType: .coupon, itemID: 3), code: "VALID3"))
        return [coupon1, coupon2, coupon3]
    }

    static func makeSecondPageCoupons() -> [POSItem] {
        let coupon4 = POSItem.coupon(POSCoupon(id: POSItemIdentifier(underlyingType: .coupon, itemID: 4), code: "VALID4"))
        let coupon5 = POSItem.coupon(POSCoupon(id: POSItemIdentifier(underlyingType: .coupon, itemID: 5), code: "VALID5"))
        let coupon6 = POSItem.coupon(POSCoupon(id: POSItemIdentifier(underlyingType: .coupon, itemID: 6), code: "VALID6"))
        return [coupon4, coupon5, coupon6]
    }

    func enableCoupons() async throws {
        if let error = errorToThrow {
            throw error
        }
    }
}
