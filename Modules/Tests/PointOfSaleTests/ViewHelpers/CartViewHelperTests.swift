import Foundation
import Testing
@testable import PointOfSale
import struct Yosemite.POSCustomAmount
import struct Yosemite.POSItemIdentifier

struct CartViewHelperTests {
    let sut = CartViewHelper()

    @Test func shouldPreventCartEditing_when_card_paymentState_idle_and_order_is_syncing() async throws {
        // Given

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: .syncing,
                                             paymentState: PointOfSalePaymentState(card: .idle, cash: .idle)) == true)
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
                                             paymentState: PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle)) == true)
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
                                             paymentState: PointOfSalePaymentState(card: .processingPayment, cash: .idle)) == true)
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
                                             paymentState: PointOfSalePaymentState(card: .acceptingCard, cash: .idle)) == false)
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
                                             paymentState: PointOfSalePaymentState(card: .validatingOrderError, cash: .idle)) == false)
    }

    @Test func shouldPreventCartEditing_when_card_paymentState_cardInserted() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00",
            orderTotalDecimal: 12.0))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: PointOfSalePaymentState(card: .cardInserted, cash: .idle)) == true)
    }

    @Test func shouldPreventCartEditing_false_when_card_paymentState_paymentIntentCreationError() async throws {
        // When
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00",
            orderTotalDecimal: 12.0))

        // Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: PointOfSalePaymentState(card: .paymentIntentCreationError, cash: .idle)) == false)
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
        let coupon = Cart.CouponItem(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "TEST10", summary: "")
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
        let coupon = Cart.CouponItem(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "TEST10", summary: "")

        // When, Then
        #expect(sut.couponRowState(orderStage: .finalizing,
                                   orderState: .syncing,
                                   couponItem: coupon) == .validating)
    }

    @Test func couponRowState_finalizing_and_loaded_with_matching_coupon_returns_valid() async throws {
        // Given
        let couponCode = "TEST10"
        let coupon = Cart.CouponItem(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: couponCode, summary: "")
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
        let coupon = Cart.CouponItem(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "TEST10", summary: "")
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
        let coupon = Cart.CouponItem(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "TEST10", summary: "")

        // When, Then
        #expect(sut.couponRowState(orderStage: .finalizing,
                                   orderState: .error(.invalidCoupon("Invalid coupon"), {}),
                                   couponItem: coupon) == .invalid)
    }

    @Test func couponRowState_finalizing_and_other_error_returns_idle() async throws {
        // Given
        let coupon = Cart.CouponItem(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "TEST10", summary: "")

        // When, Then
        #expect(sut.couponRowState(orderStage: .finalizing,
                                   orderState: .error(.other("Some other error"), {}),
                                   couponItem: coupon) == .idle)
    }

    @Test func shouldShowCheckout_when_not_building_stage_returns_false() async throws {
        // Given
        let cart = Cart(purchasableItems: [makeItem()])

        // When, Then
        #expect(sut.shouldShowCheckout(orderStage: .finalizing, cart: cart) == false)
    }

    @Test func shouldShowCheckout_when_building_stage_and_empty_cart_returns_false() async throws {
        // Given
        let cart = Cart()

        // When, Then
        #expect(sut.shouldShowCheckout(orderStage: .building, cart: cart) == false)
    }

    @Test func shouldShowCheckout_when_building_stage_and_cart_has_purchasable_items_returns_true() async throws {
        // Given
        let cart = Cart(purchasableItems: [makeItem()])

        // When, Then
        #expect(sut.shouldShowCheckout(orderStage: .building, cart: cart) == true)
    }

    @Test func shouldShowCheckout_when_building_stage_and_cart_has_only_custom_amounts_returns_true() async throws {
        // Given
        let cart = Cart(customAmounts: [POSCustomAmount(name: "Service fee", amount: "10.00", isTaxable: true)])

        // When, Then
        #expect(sut.shouldShowCheckout(orderStage: .building, cart: cart) == true)
    }

    @Test func hasUnresolvedItems_when_cart_is_empty_returns_false() async throws {
        // Given
        let cart = Cart()

        // When, Then
        #expect(sut.hasUnresolvedItems(cart: cart) == false)
    }

    @Test func hasUnresolvedItems_when_cart_has_only_loaded_items_returns_false() async throws {
        // Given
        let cart = Cart(purchasableItems: [makeItem()])

        // When, Then
        #expect(sut.hasUnresolvedItems(cart: cart) == false)
    }

    @Test func hasUnresolvedItems_when_cart_has_loading_item_returns_true() async throws {
        // Given
        let loadingItem = Cart.PurchasableItem.loading(id: UUID())
        let cart = Cart(purchasableItems: [loadingItem])

        // When, Then
        #expect(sut.hasUnresolvedItems(cart: cart) == true)
    }

    @Test func hasUnresolvedItems_when_cart_has_error_item_returns_true() async throws {
        // Given
        let errorItem = Cart.PurchasableItem(
            id: UUID(),
            title: "",
            subtitle: "",
            quantity: 1,
            state: .error
        )
        let cart = Cart(purchasableItems: [errorItem])

        // When, Then
        #expect(sut.hasUnresolvedItems(cart: cart) == true)
    }

    @Test func hasUnresolvedItems_when_cart_has_mixed_items_returns_true() async throws {
        // Given
        let loadingItem = Cart.PurchasableItem.loading(id: UUID())
        let loadedItem = makeItem()
        let cart = Cart(purchasableItems: [loadingItem, loadedItem])

        // When, Then
        #expect(sut.hasUnresolvedItems(cart: cart) == true)
    }
}

private func makeItem() -> Cart.PurchasableItem {
    .init(id: UUID(),
          item: MockPOSOrderableItem(name: "Item", formattedPrice: "$1.00"),
          title: "Item",
          subtitle: nil,
          quantity: 1)
}
