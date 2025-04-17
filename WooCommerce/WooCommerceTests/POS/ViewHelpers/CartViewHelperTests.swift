import Foundation
import Testing
@testable import WooCommerce

struct CartViewHelperTests {
    let sut = CartViewHelper()

    @Test func shouldPreventCartEditing_when_card_paymentState_idle_and_order_is_syncing() async throws {
        // Given

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: .syncing,
                                             paymentState: .card(.idle)) == true)
    }

    @Test func shouldPreventCartEditing_when_card_paymentState_cardPaymentSuccessful() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00",
            orderTotalDecimal: 12.0))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .card(.cardPaymentSuccessful)) == true)
    }

    @Test func shouldPreventCartEditing_when_card_paymentState_processingPayment() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00",
            orderTotalDecimal: 12.0))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .card(.processingPayment)) == true)
    }

    @Test func shouldPreventCartEditing_false_when_card_paymentState_acceptingCard() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00",
            orderTotalDecimal: 12.0))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .card(.acceptingCard)) == false)
    }

    @Test func shouldPreventCartEditing_false_when_card_paymentState_validatingOrderError() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00",
            orderTotalDecimal: 12.0))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .card(.validatingOrderError)) == false)
    }

    @Test(arguments: zip([0, 1, 2, 3], [nil, "1 item", "2 items", "3 items"]))
    func itemsInCartLabel(_ count: Int, _ expected: String?) async throws {
        // Given

        // When, Then
        #expect(sut.itemsInCartLabel(for: count) == expected)
    }

    @Test func shouldShowClearCartButton_empty_cart_false() async throws {
        #expect(sut.shouldShowClearCartButton(cart: .init(), orderStage: .building) == false)
        #expect(sut.shouldShowClearCartButton(cart: .init(), orderStage: .finalizing) == false)
    }

    @Test func shouldShowClearCartButton_items_in_cart_and_building_true() async throws {
        #expect(sut.shouldShowClearCartButton(cart: .init(purchasableItems: [makeItem()]), orderStage: .building) == true)
    }

    @Test func shouldShowClearCartButton_items_in_cart_and_finalizing_false() async throws {
        #expect(sut.shouldShowClearCartButton(cart: .init(purchasableItems: [makeItem()]), orderStage: .finalizing) == false)
    }

    @Test func couponRowState_building_stage_returns_idle() async throws {
        // Given
        let coupon = Cart.CouponItem(id: UUID(), code: "TEST10", summary: "")
        let orderState = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00",
            orderTotalDecimal: 12.0))

        // When, Then
        #expect(sut.couponRowState(orderStage: .building,
                                   orderState: orderState,
                                   couponItem: coupon) == .idle)
    }

    @Test func couponRowState_finalizing_and_syncing_returns_validating() async throws {
        // Given
        let coupon = Cart.CouponItem(id: UUID(), code: "TEST10", summary: "")

        // When, Then
        #expect(sut.couponRowState(orderStage: .finalizing,
                                   orderState: .syncing,
                                   couponItem: coupon) == .validating)
    }

    @Test func couponRowState_finalizing_and_loaded_with_matching_coupon_returns_valid() async throws {
        // Given
        let couponCode = "TEST10"
        let coupon = Cart.CouponItem(id: UUID(), code: couponCode, summary: "")
        let couponTotal = PointOfSaleCouponTotal(code: couponCode, total: "10.00")
        let orderTotals = PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00",
            orderTotalDecimal: 12.0,
            couponsTotals: [couponTotal])

        // When, Then
        #expect(sut.couponRowState(orderStage: .finalizing,
                                   orderState: .loaded(orderTotals),
                                   couponItem: coupon) == .valid(couponTotal))
    }

    @Test func couponRowState_finalizing_and_loaded_with_no_matching_coupon_returns_idle() async throws {
        // Given
        let coupon = Cart.CouponItem(id: UUID(), code: "TEST10", summary: "")
        let orderTotals = PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00",
            orderTotalDecimal: 12.0,
            couponsTotals: [])

        // When, Then
        #expect(sut.couponRowState(orderStage: .finalizing,
                                   orderState: .loaded(orderTotals),
                                   couponItem: coupon) == .idle)
    }

    @Test func couponRowState_finalizing_and_invalid_coupon_error_returns_invalid() async throws {
        // Given
        let coupon = Cart.CouponItem(id: UUID(), code: "TEST10", summary: "")

        // When, Then
        #expect(sut.couponRowState(orderStage: .finalizing,
                                   orderState: .error(.invalidCoupon("Invalid coupon"), {}),
                                   couponItem: coupon) == .invalid)
    }

    @Test func couponRowState_finalizing_and_other_error_returns_idle() async throws {
        // Given
        let coupon = Cart.CouponItem(id: UUID(), code: "TEST10", summary: "")

        // When, Then
        #expect(sut.couponRowState(orderStage: .finalizing,
                                   orderState: .error(.other("Some other error"), {}),
                                   couponItem: coupon) == .idle)
    }
}

private func makeItem() -> Cart.PurchasableItem {
    .init(id: UUID(),
          item: MockPOSOrderableItem(name: "Item", formattedPrice: "$1.00"),
          title: "Item",
          subtitle: nil,
          quantity: 1)
}
