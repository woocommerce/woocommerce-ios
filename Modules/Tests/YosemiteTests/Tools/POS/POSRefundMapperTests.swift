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

    @Test func test_map_when_refundedItemID_matches_custom_amount_then_marks_lump_sum() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(name: "Discount Fee", refundedItemID: "777")])
        let customAmount = makeCustomAmount(id: 777, name: "Discount Fee")

        // When
        let result = sut.map(refund: refund,
                             orderItems: [],
                             customAmounts: [customAmount],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.isLumpSum == true)
    }

    @Test func test_map_when_refundedItemID_matches_order_item_then_does_not_mark_lump_sum() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(name: "Mug", refundedItemID: "42")])
        let orderItem = makeOrderItem(itemID: 42, imageSrc: nil)
        let customAmount = makeCustomAmount(id: 777, name: "Discount Fee")

        // When
        let result = sut.map(refund: refund,
                             orderItems: [orderItem],
                             customAmounts: [customAmount],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.isLumpSum == false)
    }

    @Test func test_map_when_no_custom_amounts_passed_then_does_not_mark_lump_sum() {
        // Given
        let refund = makeRefund(items: [makeRefundItem(name: "Mug", refundedItemID: "42")])

        // When
        let result = sut.map(refund: refund,
                             orderItems: [],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.isLumpSum == false)
    }

    @Test func test_map_with_mixed_items_then_flags_only_fee_lines() {
        // Given
        let refund = makeRefund(items: [
            makeRefundItem(name: "Mug", refundedItemID: "42"),
            makeRefundItem(name: "Discount Fee", refundedItemID: "777")
        ])
        let orderItem = makeOrderItem(itemID: 42, imageSrc: nil)
        let customAmount = makeCustomAmount(id: 777, name: "Discount Fee")

        // When
        let result = sut.map(refund: refund,
                             orderItems: [orderItem],
                             customAmounts: [customAmount],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.count == 2)
        #expect(result.first(where: { $0.name == "Mug" })?.isLumpSum == false)
        #expect(result.first(where: { $0.name == "Discount Fee" })?.isLumpSum == true)
    }

    @Test func test_map_when_refund_has_fee_lines_then_appends_lump_sum_rows() {
        // Given - the refund's fee_line has its own id (12345) and points back via _refunded_item_id (777)
        let refund = makeRefund(
            items: [],
            feeLines: [makeFeeLine(feeID: 12345, name: "Discount Fee", total: "-5.00", refundedItemID: 777)]
        )

        // When
        let result = sut.map(refund: refund,
                             orderItems: [],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then - refundedItemID resolves to the original order fee id, not the refund-side id
        #expect(result.count == 1)
        let row = try! #require(result.first)
        #expect(row.refundedItemID == 777)
        #expect(row.name == "Discount Fee")
        #expect(row.isLumpSum == true)
        #expect(row.imageSrc == nil)
        #expect(row.formattedPrice.contains("5.00"))
        #expect(row.formattedTotal.contains("-"))
    }

    @Test func test_map_when_fee_line_has_no_refunded_meta_then_falls_back_to_fee_id() {
        // Given - missing _refunded_item_id meta (defensive fallback)
        let refund = makeRefund(items: [], feeLines: [makeFeeLine(feeID: 12345, name: "Discount Fee", total: "-5.00")])

        // When
        let result = sut.map(refund: refund,
                             orderItems: [],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.first?.refundedItemID == 12345)
    }

    @Test func test_map_with_fee_line_and_line_item_then_returns_both_rows_in_order() {
        // Given
        let refund = makeRefund(
            items: [makeRefundItem(name: "Mug", refundedItemID: "42")],
            feeLines: [makeFeeLine(feeID: 12345, name: "Discount Fee", total: "-5.00", refundedItemID: 777)]
        )

        // When
        let result = sut.map(refund: refund,
                             orderItems: [makeOrderItem(itemID: 42, imageSrc: nil)],
                             currencyFormatter: currencyFormatter,
                             currency: currency)

        // Then
        #expect(result.count == 2)
        #expect(result[0].name == "Mug")
        #expect(result[0].isLumpSum == false)
        #expect(result[1].name == "Discount Fee")
        #expect(result[1].isLumpSum == true)
        #expect(result[1].refundedItemID == 777)
    }
}

private extension POSRefundMapperTests {
    func makeRefund(items: [OrderItemRefund], feeLines: [OrderFeeLine] = []) -> Refund {
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
               shippingLines: nil,
               feeLines: feeLines)
    }

    func makeFeeLine(feeID: Int64,
                     name: String,
                     total: String,
                     totalTax: String = "0.00",
                     refundedItemID: Int64? = nil) -> OrderFeeLine {
        OrderFeeLine(feeID: feeID,
                     name: name,
                     taxClass: "",
                     taxStatus: .none,
                     total: total,
                     totalTax: totalTax,
                     taxes: [],
                     attributes: [],
                     refundedItemID: refundedItemID)
    }

    func makeRefundItem(name: String = "Test Item",
                        refundedItemID: String? = "1",
                        quantity: Decimal = -1,
                        price: NSDecimalNumber = NSDecimalNumber(value: -10.00),
                        total: String = "-10.00") -> OrderItemRefund {
        OrderItemRefund(itemID: 0,
                        name: name,
                        refundedItemID: refundedItemID,
                        quantity: quantity,
                        price: price,
                        subtotal: total,
                        subtotalTax: "0.00",
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
                        refundedItemID: refundedItemID,
                        quantity: quantity,
                        price: price,
                        subtotal: total,
                        subtotalTax: "0.00",
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

    func makeCustomAmount(id: Int64, name: String) -> POSOrderCustomAmount {
        POSOrderCustomAmount(id: id,
                             name: name,
                             formattedTotal: "$5.00",
                             total: 5,
                             totalTax: 0)
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

    @Test func mapSubtotalAndTax_when_refund_has_fee_lines_then_includes_them_in_subtotal_and_tax() {
        // Given
        let sut = POSRefundMapper()
        let refund = makeRefund(
            items: [makeRefundItemWithTax(total: "-10.00", totalTax: "-1.00")],
            feeLines: [makeFeeLine(feeID: 777, name: "Discount Fee", total: "-5.00", totalTax: "-0.50")]
        )
        let formatter = CurrencyFormatter(currencySettings: .init())

        // When
        let result = sut.mapSubtotalAndTax(refund: refund, currencyFormatter: formatter, currency: "USD")

        // Then - product 10 + fee 5 = 15, taxes 1 + 0.5 = 1.50
        #expect(result.formattedSubtotal.contains("15.00"))
        #expect(result.formattedTax.contains("1.50"))
    }
}
