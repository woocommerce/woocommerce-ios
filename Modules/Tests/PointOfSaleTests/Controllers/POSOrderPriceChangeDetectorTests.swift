import Testing
import Foundation

@testable import PointOfSale
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.POSItemIdentifier
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation

struct POSOrderPriceChangeDetectorTests {
    private let sut = POSOrderPriceChangeDetector()

    // MARK: - No change scenarios

    @Test func detectsPriceChange_when_exTax_price_matches_then_returns_false() {
        // Given
        let cart = makeCart(price: "10.00", productID: 42)
        let order = makeOrder(productID: 42, quantity: 1, subtotal: "10.00", subtotalTax: "0.00")

        // When
        let result = sut.detectsPriceChange(cart: cart, order: order)

        // Then
        #expect(result == false)
    }

    @Test func detectsPriceChange_when_taxInclusive_price_matches_then_returns_false() {
        // Given
        let cart = makeCart(price: "11.00", productID: 42)
        let order = makeOrder(productID: 42, quantity: 1, subtotal: "10.00", subtotalTax: "1.00")

        // When
        let result = sut.detectsPriceChange(cart: cart, order: order)

        // Then
        #expect(result == false)
    }

    @Test func detectsPriceChange_when_server_tax_rounding_differs_then_returns_false() {
        // Given: product price $180 (incl tax), server returns subtotal + tax = 179.99782200
        let cart = makeCart(price: "180", productID: 80)
        let order = makeOrder(productID: 80, quantity: 1, subtotal: "178.21782200", subtotalTax: "1.78000000")

        // When
        let result = sut.detectsPriceChange(cart: cart, order: order)

        // Then
        #expect(result == false)
    }

    @Test func detectsPriceChange_when_consolidated_items_match_then_returns_false() {
        // Given: two cart items of the same product consolidated into one order line
        let product = makeSimpleProduct(price: "10.00", productID: 42)
        let cart = Cart(purchasableItems: [
            Cart.PurchasableItem(id: UUID(), item: product, title: "Widget", subtitle: nil, quantity: 1),
            Cart.PurchasableItem(id: UUID(), item: product, title: "Widget", subtitle: nil, quantity: 1)
        ])
        let order = makeOrder(productID: 42, quantity: 2, subtotal: "20.00", subtotalTax: "0.00")

        // When
        let result = sut.detectsPriceChange(cart: cart, order: order)

        // Then
        #expect(result == false)
    }

    @Test func detectsPriceChange_when_cart_empty_then_returns_false() {
        // Given
        let cart = Cart()
        let order = Order.fake()

        // When
        let result = sut.detectsPriceChange(cart: cart, order: order)

        // Then
        #expect(result == false)
    }

    // MARK: - Change detected scenarios

    @Test func detectsPriceChange_when_simple_product_price_changed_then_returns_true() {
        // Given: cart price $12 but order shows $10 ex-tax / $11 tax-inclusive
        let cart = makeCart(price: "12.00", productID: 42)
        let order = makeOrder(productID: 42, quantity: 1, subtotal: "10.00", subtotalTax: "1.00")

        // When
        let result = sut.detectsPriceChange(cart: cart, order: order)

        // Then
        #expect(result == true)
    }

    @Test func detectsPriceChange_when_variation_price_changed_then_returns_true() {
        // Given
        let variation = POSVariation(id: POSItemIdentifier(underlyingType: .variation, itemID: 99),
                                     name: "Blue / Large",
                                     formattedPrice: "$9.00",
                                     price: "9.00",
                                     productID: 10,
                                     variationID: 99,
                                     parentProductName: "T-Shirt")
        let cart = Cart(purchasableItems: [
            Cart.PurchasableItem(id: UUID(), item: variation, title: "T-Shirt", subtitle: "Blue / Large", quantity: 1)
        ])
        let order = Order.fake().copy(items: [
            OrderItem.fake().copy(productID: 10, variationID: 99, quantity: 1, subtotal: "8.00", subtotalTax: "0.80")
        ])

        // When
        let result = sut.detectsPriceChange(cart: cart, order: order)

        // Then
        #expect(result == true)
    }

    @Test func detectsPriceChange_when_one_cent_change_then_returns_true() {
        // Given
        let cart = makeCart(price: "10.00", productID: 42)
        let order = makeOrder(productID: 42, quantity: 1, subtotal: "9.99", subtotalTax: "0.00")

        // When
        let result = sut.detectsPriceChange(cart: cart, order: order)

        // Then
        #expect(result == true)
    }
}

// MARK: - Helpers

private extension POSOrderPriceChangeDetectorTests {
    func makeSimpleProduct(price: String, productID: Int64) -> POSSimpleProduct {
        POSSimpleProduct(id: POSItemIdentifier(underlyingType: .product, itemID: productID),
                         name: "Product \(productID)",
                         formattedPrice: "$\(price)",
                         productID: productID,
                         price: price,
                         manageStock: false,
                         stockQuantity: nil,
                         stockStatusKey: "instock")
    }

    func makeCart(price: String, productID: Int64) -> Cart {
        let product = makeSimpleProduct(price: price, productID: productID)
        return Cart(purchasableItems: [
            Cart.PurchasableItem(id: UUID(), item: product, title: product.name, subtitle: nil, quantity: 1)
        ])
    }

    func makeOrder(productID: Int64, quantity: Decimal, subtotal: String, subtotalTax: String) -> Order {
        Order.fake().copy(items: [
            OrderItem.fake().copy(productID: productID, variationID: 0, quantity: quantity, subtotal: subtotal, subtotalTax: subtotalTax)
        ])
    }
}
