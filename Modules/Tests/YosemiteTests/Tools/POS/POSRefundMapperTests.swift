import Testing
import Foundation
@testable import Yosemite
@testable import NetworkingCore
import class WooFoundation.CurrencySettings
import class WooFoundation.CurrencyFormatter

struct POSRefundMapperTests {
    private let sut = POSRefundMapper()
    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
    private let currency = CurrencySettings().currencyCode.rawValue

    @Test func test_map_then_maps_name_from_refund_item() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(name: "Coffee Mug")])

        // When
        let result = sut.map(refund: refund,
                                            orderItems: [],
                                            currencyFormatter: currencyFormatter,
                                            currency: currency)

        // Then
        #expect(result.first?.name == "Coffee Mug")
    }

    @Test func test_map_then_converts_quantity_to_absolute_value() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(quantity: -2)])

        // When
        let result = sut.map(refund: refund,
                             orderItems: [],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.quantity == 2)
    }

    @Test func test_map_then_formats_price_as_positive() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(price: NSDecimalNumber(value: -14.99))])

        // When
        let result = sut.map(refund: refund,
                             orderItems: [],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.formattedPrice.contains("-") == false)
        #expect(result.first?.formattedPrice.contains("14.99") == true)
    }

    @Test func test_map_then_formats_total_as_negative() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(total: "-14.99")])

        // When
        let result = sut.map(refund: refund,
                             orderItems: [],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.formattedTotal.contains("-") == true)
        #expect(result.first?.formattedTotal.contains("14.99") == true)
    }

    @Test func test_map_when_order_item_matches_then_resolves_image() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(refundedItemID: "42")])
        let orderItem = makeOrderItem(itemID: 42, imageSrc: "https://example.com/img.jpg")

        // When
        let result = sut.map(refund: refund,
                             orderItems: [orderItem],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.imageSrc == "https://example.com/img.jpg")
    }

    @Test func test_map_when_no_matching_order_item_then_image_is_nil() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(refundedItemID: "42")])
        let orderItem = makeOrderItem(itemID: 99, imageSrc: "https://example.com/img.jpg")

        // When
        let result = sut.map(refund: refund,
                             orderItems: [orderItem],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.imageSrc == nil)
    }

    @Test func test_map_when_refundedItemID_is_nil_then_image_is_nil() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(name: "Deleted Product", refundedItemID: nil)])

        // When
        let result = sut.map(refund: refund,
                             orderItems: [],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.imageSrc == nil)
        #expect(result.first?.name == "Deleted Product")
    }

    @Test func test_map_with_multiple_items_then_returns_all() {
        // Given
        let refund = makeRefund(items: [
            makeRefundItem(name: "Item A"),
            makeRefundItem(name: "Item B"),
            makeRefundItem(name: "Item C")
        ])

        // When
        let result = sut.map(refund: refund,
                                            orderItems: [],
                                            currencyFormatter: currencyFormatter,
                                            currency: currency)

        // Then
        #expect(result.count == 3)
        #expect(result.map(\.name) == ["Item A", "Item B", "Item C"])
    }
}

private extension POSRefundMapperTests {
    func makeRefund(items: [OrderItemRefund]) -> Refund {
        Refund(refundID: 1,
               orderID: 100,
               siteID: 123,
               dateCreated: Date(),
               amount: "14.99",
               reason: "Test",
               refundedByUserID: 0,
               isAutomated: nil,
               createAutomated: nil,
               items: items,
               shippingLines: nil)
    }

    func makeRefundItem(name: String = "Test Item",
                        refundedItemID: String? = "1",
                        quantity: Decimal = -1,
                        price: NSDecimalNumber = NSDecimalNumber(value: -10.00),
                        total: String = "-10.00") -> OrderItemRefund {
        OrderItemRefund(itemID: 0,
                        name: name,
                        productID: 0,
                        variationID: 0,
                        refundedItemID: refundedItemID,
                        quantity: quantity,
                        price: price,
                        sku: nil,
                        subtotal: total,
                        subtotalTax: "0.00",
                        taxClass: "",
                        taxes: [],
                        total: total,
                        totalTax: "0.00")
    }

    func makeRefundItemWithTax(name: String = "Item",
                               refundedItemID: String? = "1",
                               quantity: Decimal = -1,
                               price: NSDecimalNumber = 10.00,
                               total: String = "-10.00",
                               totalTax: String = "-2.00") -> OrderItemRefund {
        OrderItemRefund(itemID: 0,
                        name: name,
                        productID: 0,
                        variationID: 0,
                        refundedItemID: refundedItemID,
                        quantity: quantity,
                        price: price,
                        sku: nil,
                        subtotal: total,
                        subtotalTax: "0.00",
                        taxClass: "",
                        taxes: [],
                        total: total,
                        totalTax: totalTax)
    }

    func makeOrderItem(itemID: Int64, imageSrc: String?) -> POSOrderItem {
        POSOrderItem(itemID: itemID,
                     name: "Order Item",
                     quantity: 1,
                     price: 10.00,
                     total: 10.00,
                     totalTax: 0,
                     formattedPrice: "$10.00",
                     formattedTotal: "$10.00",
                     imageSrc: imageSrc,
                     attributes: [])
    }
}

// MARK: - mapSubtotalAndTax Tests

extension POSRefundMapperTests {
    @Test func mapSubtotalAndTax_then_returns_formatted_absolute_subtotal_and_tax() {
        // Given
        let sut = POSRefundMapper()
        let items = [
            makeRefundItemWithTax(total: "-18.00", totalTax: "-3.60"),
            makeRefundItemWithTax(total: "-10.00", totalTax: "-2.00")
        ]
        let refund = makeRefund(items: items)
        let formatter = CurrencyFormatter(currencySettings: .init())

        // When
        let result = sut.mapSubtotalAndTax(refund: refund, currencyFormatter: formatter, currency: "USD")

        // Then
        #expect(result.formattedSubtotal.contains("28.00"))
        #expect(result.formattedTax.contains("5.60"))
    }

    @Test func mapSubtotalAndTax_when_no_items_then_returns_zero_amounts() {
        // Given
        let sut = POSRefundMapper()
        let refund = makeRefund(items: [])
        let formatter = CurrencyFormatter(currencySettings: .init())

        // When
        let result = sut.mapSubtotalAndTax(refund: refund, currencyFormatter: formatter, currency: "USD")

        // Then
        #expect(result.formattedSubtotal.contains("0.00"))
        #expect(result.formattedTax.contains("0.00"))
    }
}
