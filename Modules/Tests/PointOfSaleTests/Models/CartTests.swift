import Foundation
import Testing
@testable import PointOfSale
import struct Yosemite.POSCustomAmount
import struct Yosemite.POSItemIdentifier

struct CartTests {
    @Test func test_totalItemCount_when_cart_is_empty_then_returns_zero() {
        // Given
        let cart = Cart()

        // When, Then
        #expect(cart.totalItemCount == 0)
    }

    @Test func test_totalItemCount_when_cart_has_only_a_coupon_then_count_is_one() {
        // Given
        var cart = Cart()
        cart.coupons = [makeCoupon(code: "FREESHIP")]

        // When, Then
        #expect(cart.totalItemCount == 1)
        #expect(cart.isNotEmpty)
    }

    @Test func test_totalItemCount_when_cart_has_only_a_custom_amount_then_count_is_one() {
        // Given
        var cart = Cart()
        cart.customAmounts = [POSCustomAmount(name: "Service fee", amount: "10.00", isTaxable: true)]

        // When, Then
        #expect(cart.totalItemCount == 1)
    }

    @Test func test_totalItemCount_sums_purchasableItems_coupons_and_customAmounts() {
        // Given
        var cart = Cart()
        cart.purchasableItems = [
            Cart.PurchasableItem.loading(id: UUID()),
            Cart.PurchasableItem.loading(id: UUID())
        ]
        cart.coupons = [makeCoupon(code: "FREESHIP")]
        cart.customAmounts = [
            POSCustomAmount(name: "Service fee", amount: "10.00", isTaxable: true),
            POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)
        ]

        // When, Then
        #expect(cart.totalItemCount == 5)
    }

    private func makeCoupon(code: String) -> Cart.CouponItem {
        Cart.CouponItem(
            id: UUID(),
            posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1),
            code: code,
            summary: "Free shipping"
        )
    }
}
