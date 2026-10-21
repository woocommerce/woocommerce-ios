import Foundation
import Testing
@testable import PointOfSale
import struct Yosemite.POSCustomAmount
import struct Yosemite.POSItemIdentifier
import enum Yosemite.POSItem
import struct Yosemite.POSVariation
import struct Yosemite.POSVariableParentProduct

struct CartTests {
    @Test(arguments: [("", nil), ("Size: Large, Color: Blue", "Size: Large, Color: Blue")] as [(String, String?)], [false, true])
    func test_add_when_variation_has_name_then_subtitle_omits_only_empty_name(variation: (name: String, subtitle: String?), isSearchResult: Bool) {
        // Given
        var cart = Cart()
        let item = makeVariation(name: variation.name, isSearchResult: isSearchResult)

        // When
        cart.add(item)

        // Then
        #expect(cart.purchasableItems.count == 1)
        #expect(cart.purchasableItems.first?.subtitle == variation.subtitle)
        #expect(cart.purchasableItems.first?.title == "Parent Product")
        #expect(cart.purchasableItems.first?.formattedPrice == "$2.00")
        #expect(cart.purchasableItems.first?.posItemIdentifier == item.id)
    }

    @Test(arguments: [("", nil), ("Size: Large, Color: Blue", "Size: Large, Color: Blue")] as [(String, String?)], [false, true])
    func test_updateLoadingItem_when_variation_has_name_then_subtitle_omits_only_empty_name(variation: (name: String, subtitle: String?),
                                                                                       isSearchResult: Bool) {
        // Given
        var cart = Cart()
        let loadingItem = cart.addLoadingItem()
        let item = makeVariation(name: variation.name, isSearchResult: isSearchResult)

        // When
        let updatedItem = cart.updateLoadingItem(id: loadingItem.id, with: item)

        // Then
        #expect(cart.purchasableItems.count == 1)
        #expect(updatedItem?.id == loadingItem.id)
        #expect(updatedItem?.subtitle == variation.subtitle)
        #expect(cart.purchasableItems.first?.subtitle == variation.subtitle)
        #expect(updatedItem?.posItemIdentifier == item.id)
    }

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

    @Test func test_isEmpty_when_cart_is_new_then_returns_true() {
        // Given
        let cart = Cart()

        // When, Then
        #expect(cart.isEmpty)
    }

    @Test func test_isEmpty_when_only_a_loading_placeholder_was_added_then_returns_false() {
        // Given
        var cart = Cart()

        // When
        _ = cart.addLoadingItem()

        // Then
        #expect(cart.isEmpty == false)
        #expect(cart.totalItemCount == 1)
    }

    private func makeVariation(name: String, isSearchResult: Bool) -> POSItem {
        let variation = POSVariation(id: POSItemIdentifier(underlyingType: .variation, itemID: 2),
                                     name: name,
                                     formattedPrice: "$2.00",
                                     price: "2.00",
                                     productID: 1,
                                     variationID: 2,
                                     parentProductName: "Parent Product")
        if isSearchResult {
            let parent = POSVariableParentProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
                                                  name: "Parent Product",
                                                  productImageSource: nil,
                                                  productID: 1)
            return .searchResultVariation(variation, parentProduct: parent)
        }
        return .variation(variation)
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
