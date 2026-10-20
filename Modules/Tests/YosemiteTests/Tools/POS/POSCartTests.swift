import Foundation
import Testing
@testable import Yosemite

struct POSCartTests {
    @Test func test_equality_when_carts_create_the_same_order_then_returns_true() {
        // Given
        let customAmount = POSCustomAmount(name: "Tip", amount: "2.00", isTaxable: false)
        let coupon = POSCoupon(id: POSItemIdentifier(underlyingType: .coupon, itemID: 9), code: "SAVE")

        // When
        let cart = makeCart(items: [(productID: 1, quantity: 2)], coupons: [coupon], customAmounts: [customAmount])
        let sameCart = makeCart(items: [(productID: 1, quantity: 2)], coupons: [coupon], customAmounts: [customAmount])

        // Then
        #expect(cart == sameCart)
    }

    @Test func test_equality_when_item_quantity_differs_then_returns_false() {
        // When, Then
        #expect(makeCart(items: [(productID: 1, quantity: 1)]) != makeCart(items: [(productID: 1, quantity: 2)]))
    }

    @Test func test_equality_when_item_differs_then_returns_false() {
        // When, Then
        #expect(makeCart(items: [(productID: 1, quantity: 1)]) != makeCart(items: [(productID: 2, quantity: 1)]))
    }

    @Test func test_equality_when_coupons_differ_then_returns_false() {
        // Given
        let coupon = POSCoupon(id: POSItemIdentifier(underlyingType: .coupon, itemID: 9), code: "SAVE")

        // When, Then
        #expect(makeCart(items: [(productID: 1, quantity: 1)], coupons: [coupon]) != makeCart(items: [(productID: 1, quantity: 1)]))
    }

    @Test func test_equality_when_custom_amount_taxable_intent_differs_then_returns_false() {
        // Given
        let customAmount = POSCustomAmount(name: "Tip", amount: "2.00", isTaxable: false)
        let taxableCustomAmount = POSCustomAmount(id: customAmount.id, name: "Tip", amount: "2.00", isTaxable: true)

        // When, Then
        #expect(makeCart(customAmounts: [customAmount]) != makeCart(customAmounts: [taxableCustomAmount]))
    }
}

private extension POSCartTests {
    func makeCart(items: [(productID: Int64, quantity: Decimal)] = [],
                  coupons: [POSCoupon] = [],
                  customAmounts: [POSCustomAmount] = []) -> POSCart {
        POSCart(items: items.map { POSCartItem(item: makeProduct(productID: $0.productID), quantity: $0.quantity) },
                coupons: coupons,
                customAmounts: customAmounts)
    }

    func makeProduct(productID: Int64) -> POSSimpleProduct {
        POSSimpleProduct(id: POSItemIdentifier(underlyingType: .product, itemID: productID),
                         name: "Product",
                         formattedPrice: "$10.00",
                         productID: productID,
                         price: "10.00",
                         manageStock: false,
                         stockQuantity: nil,
                         stockStatusKey: "")
    }
}
