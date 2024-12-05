import Foundation
import Testing
@testable import WooCommerce

struct CartViewHelperTests {
    let sut = CartViewHelper()

    @Test func shouldPreventCartEditing_when_paymentState_idle_and_order_is_syncing() async throws {
        // Given

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: .syncing,
                                             paymentState: .idle) == true)
    }

    @Test func shouldPreventCartEditing_when_paymentState_cardPaymentSuccessful() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00"))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .cardPaymentSuccessful) == true)
    }

    @Test func shouldPreventCartEditing_when_paymentState_processingPayment() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00"))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .processingPayment) == true)
    }

    @Test func shouldPreventCartEditing_false_when_paymentState_acceptingCard() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00"))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .acceptingCard) == false)
    }

    @Test func shouldPreventCartEditing_false_when_paymentState_validatingOrderError() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00"))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .validatingOrderError) == false)
    }

    @Test(arguments: zip([0, 1, 2, 3], [nil, "1 item", "2 items", "3 items"]))
    func itemsInCartLabel(_ count: Int, _ expected: String?) async throws {
        // Given

        // When, Then
        #expect(sut.itemsInCartLabel(for: count) == expected)
    }

    @Test func shouldShowClearCartButton_empty_cart_false() async throws {
        #expect(sut.shouldShowClearCartButton(cart: [], orderStage: .building) == false)
        #expect(sut.shouldShowClearCartButton(cart: [], orderStage: .finalizing) == false)
    }

    @Test func shouldShowClearCartButton_items_in_cart_and_building_true() async throws {
        #expect(sut.shouldShowClearCartButton(cart: [makeItem()], orderStage: .building) == true)
    }

    @Test func shouldShowClearCartButton_items_in_cart_and_finalizing_false() async throws {
        #expect(sut.shouldShowClearCartButton(cart: [makeItem()], orderStage: .finalizing) == false)
    }
}

private func makeItem() -> CartItem {
    CartItem(id: UUID(), item: MockPOSItem(name: "Item", formattedPrice: "$1.00"), quantity: 1)
}
