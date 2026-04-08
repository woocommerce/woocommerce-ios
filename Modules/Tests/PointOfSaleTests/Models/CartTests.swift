import Testing
import Foundation

@testable import PointOfSale
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation
import struct Yosemite.POSItemIdentifier

struct CartTests {
    @Test func applyPriceUpdates_when_price_changed_then_updates_cart_item() {
        // Given
        let product = POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Widget",
            formattedPrice: "$10.00",
            productID: 1,
            price: "10.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        let cartItemID = UUID()
        var cart = Cart(purchasableItems: [
            Cart.PurchasableItem(id: cartItemID, item: product, title: "Widget", subtitle: nil, quantity: 2)
        ])

        let updatedProduct = POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Widget",
            formattedPrice: "$15.00",
            productID: 1,
            price: "15.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        // When
        cart.applyPriceUpdates([CartItemPriceUpdate(cartItemID: cartItemID, updatedItem: updatedProduct)])

        // Then
        let item = cart.purchasableItems.first
        #expect(item?.formattedPrice == "$15.00")
        #expect(item?.quantity == 2)
        #expect(item?.title == "Widget")
    }

    @Test func applyPriceUpdates_when_no_matching_id_then_cart_unchanged() {
        // Given
        let product = POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Widget",
            formattedPrice: "$10.00",
            productID: 1,
            price: "10.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        var cart = Cart(purchasableItems: [
            Cart.PurchasableItem(id: UUID(), item: product, title: "Widget", subtitle: nil, quantity: 1)
        ])

        let updatedProduct = POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Widget",
            formattedPrice: "$15.00",
            productID: 1,
            price: "15.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        // When — update targets a non-existent cart item ID
        cart.applyPriceUpdates([CartItemPriceUpdate(cartItemID: UUID(), updatedItem: updatedProduct)])

        // Then
        #expect(cart.purchasableItems.first?.formattedPrice == "$10.00")
    }

    @Test func applyPriceUpdates_when_empty_updates_then_cart_unchanged() {
        // Given
        let product = POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Widget",
            formattedPrice: "$10.00",
            productID: 1,
            price: "10.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        var cart = Cart(purchasableItems: [
            Cart.PurchasableItem(id: UUID(), item: product, title: "Widget", subtitle: nil, quantity: 1)
        ])

        // When
        cart.applyPriceUpdates([])

        // Then
        #expect(cart.purchasableItems.first?.formattedPrice == "$10.00")
    }
}
