@testable import WooCommerce
import Testing
import Foundation

import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSaleCouponServiceProtocol
import enum Yosemite.POSItem
import struct Yosemite.POSCoupon
import struct Yosemite.PagedItems
import struct Yosemite.POSVariableParentProduct
import enum Yosemite.PointOfSaleCouponServiceError

final class MockPointOfSaleCouponService: PointOfSaleCouponServiceProtocol {
    var shouldReturnZeroItems = false
    var errorToThrow: PointOfSaleCouponServiceError?

    func provideLocalPointOfSaleCoupons() async throws -> [Yosemite.POSItem] {
        []
    }

    func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        if let error = errorToThrow {
            throw error
        }
        if shouldReturnZeroItems {
            return .init(items: [], hasMorePages: false)
        } else {
            return .init(items: Self.makeInitialCoupons(),
                         hasMorePages: false)
        }
    }

    static func makeInitialCoupons() -> [POSItem] {
        let coupon1 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84A")) ?? UUID(), code: "VALID1"))
        let coupon2 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84B")) ?? UUID(), code: "VALID2"))
        let coupon3 = POSItem.coupon(POSCoupon(id: UUID(uuidString: ("DC55E3B9-9D83-4C07-82A7-4C300A50E84C")) ?? UUID(), code: "VALID3"))
        return [coupon1, coupon2, coupon3]
    }

    func enableCoupons() async throws {
        if let error = errorToThrow {
            throw error
        }
    }
}

struct PointOfSaleCouponsControllerTests {
    @available(iOS 17.0, *)
    @Test func loadItems_when_empty_coupons_then_results_in_empty_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        let expectedItemStackState = ItemsStackState(root: .empty, itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadItems(base: .root(.coupons))

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
        await sut.loadItems(base: .root(.coupons))

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @available(iOS 17.0, *)
    @Test func refreshItems_when_empty_coupons_then_results_in_empty_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        let expectedItemStackState = ItemsStackState(root: .empty, itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.refreshItems(base: .root(.coupons))

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @available(iOS 17.0, *)
    @Test func refreshItems_when_some_coupons_then_results_in_coupons_loaded_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let expectedCoupons = MockPointOfSaleCouponService.makeInitialCoupons()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        let expectedItemStackState = ItemsStackState(root: .loaded(expectedCoupons, hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.refreshItems(base: .root(.coupons))

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_when_empty_coupons_then_results_in_empty_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        let expectedItemStackState = ItemsStackState(root: .empty, itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadNextItems(base: .root(.coupons))

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_when_some_coupons_then_results_in_coupons_loaded_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let expectedCoupons = MockPointOfSaleCouponService.makeInitialCoupons()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        let expectedItemStackState = ItemsStackState(root: .loaded(expectedCoupons, hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadNextItems(base: .root(.coupons))

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @available(iOS 17.0, *)
    @Test func loadItems_when_retrieving_settings_fails_then_results_in_error_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.errorToThrow = .couponsLoadingError
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        let expectedItemStackState = ItemsStackState(root: .error(.errorOnLoadingCoupons), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadItems(base: .root(.coupons))

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @available(iOS 17.0, *)
    @Test func enableCoupons_sets_loading_state_when_starting() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        // When
        _ = await sut.enableCoupons()

        // Then
        guard case .loading = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loading state")
            return
        }
    }

    @available(iOS 17.0, *)
    @Test func enableCoupons_sets_error_state_when_fails() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.errorToThrow = .couponsEnablingError
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        // When
        let result = await sut.enableCoupons()

        // Then
        #expect(result == false)
        guard case .error = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected error state")
            return
        }
    }

    @available(iOS 17.0, *)
    @Test func enableCoupons_returns_true_when_successful() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider)

        // When
        let result = await sut.enableCoupons()

        // Then
        #expect(result == true)
    }
}
