@testable import WooCommerce
import Testing
import Foundation

import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.POSItem
import struct Yosemite.POSCoupon
import struct Yosemite.PagedItems
import struct Yosemite.POSVariableParentProduct

final class MockPointOfSaleCouponService: PointOfSaleItemServiceProtocol{
    var shouldReturnZeroItems = false

    func providePointOfSaleItems(pageNumber: Int) async throws -> PagedItems<POSItem> {
        if shouldReturnZeroItems {
            return .init(items: [], hasMorePages: false)
        } else {
            return .init(items: Self.makeInitialCoupons(),
                         hasMorePages: false)
        }
    }

    func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        return .init(items: [], hasMorePages: false)
    }

    static func makeInitialCoupons() -> [POSItem] {
        let coupon1 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84A")) ?? UUID(), code: "VALID1"))
        let coupon2 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84B")) ?? UUID(), code: "VALID2"))
        let coupon3 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84C")) ?? UUID(), code: "VALID3"))
        return [coupon1, coupon2, coupon3]
    }
}

struct PointOfSaleCouponsControllerTests {
    @available(iOS 17.0, *)
    @Test func loadItems_when_empty_coupons_then_results_in_empty_loaded_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        let expectedItemStackState = ItemsStackState(root: .loaded([], hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @available(iOS 17.0, *)
    @Test func loadItems_when_some_coupons_then_results_in_coupons_loaded_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let expectedCoupons = MockPointOfSaleCouponService.makeInitialCoupons()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        let expectedItemStackState = ItemsStackState(root: .loaded(expectedCoupons, hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }
}
