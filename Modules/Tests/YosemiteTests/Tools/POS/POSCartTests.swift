import Foundation
import Testing
@testable import Yosemite

struct POSCartTests {
    @Test func totalItemCount_when_cart_is_empty_then_returns_zero() {
        // Given
        let sut = POSCart()

        // When, Then
        #expect(sut.totalItemCount == 0)
    }

    @Test func totalItemCount_when_cart_has_only_coupon_then_returns_one() {
        // Given
        let sut = POSCart(coupons: [makeCoupon()])

        // When, Then
        #expect(sut.totalItemCount == 1)
    }

    @Test func totalItemCount_sums_items_coupons_and_customAmounts() {
        // Given
        let sut = POSCart(
            items: [
                makeCartItem(),
                makeCartItem()
            ],
            coupons: [makeCoupon()],
            customAmounts: [
                POSCustomAmount(name: "Service fee", amount: "10.00", isTaxable: true),
                POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)
            ]
        )

        // When, Then
        #expect(sut.totalItemCount == 5)
    }

    private func makeCartItem() -> POSCartItem {
        POSCartItem(
            item: MockPOSOrderableItem(name: "", formattedPrice: ""),
            quantity: 1
        )
    }

    private func makeCoupon() -> POSCoupon {
        POSCoupon(
            id: POSItemIdentifier(underlyingType: .coupon, itemID: 1),
            code: "SAVE10"
        )
    }
}
