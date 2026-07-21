import Testing
import Foundation
import Fakes
import Networking
@testable import Yosemite
@testable import Hardware

/// Unit tests for `ReceiptContentAssembler`, the pure builder that turns an `Order` +
/// `CardPresentReceiptParameters` into `ReceiptContent` (line items, cart totals, order note).
///
struct ReceiptContentAssemblerTests {

    // MARK: - Cart totals: taxes

    @Test func test_makeContent_when_order_has_taxes_then_includes_total_tax_line() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let order = makeOrder(totalTax: "10.71")

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let taxLine = content.cartTotals.first { $0.description == ReceiptContent.Localization.totalTaxLineDescription }
        #expect(taxLine?.amount == "$10.71")
    }

    @Test func test_makeContent_when_order_has_no_taxes_then_excludes_total_tax_line() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let order = makeOrder(totalTax: "0.00")

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let taxLine = content.cartTotals.first { $0.description == ReceiptContent.Localization.totalTaxLineDescription }
        #expect(taxLine == nil)
    }

    // MARK: - Cart totals: shipping

    @Test func test_makeContent_when_order_has_shipping_then_includes_shipping_line() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let order = makeOrder(shippingTotal: "5.50")

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let shippingLine = content.cartTotals.first { $0.description == ReceiptContent.Localization.shippingLineDescription }
        #expect(shippingLine?.amount == "$5.50")
    }

    @Test func test_makeContent_when_order_has_no_shipping_then_excludes_shipping_line() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let order = makeOrder(shippingTotal: "0.00")

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let shippingLine = content.cartTotals.first { $0.description == ReceiptContent.Localization.shippingLineDescription }
        #expect(shippingLine == nil)
    }

    // MARK: - Cart totals: discounts and coupons

    @Test func test_makeContent_when_order_has_discount_then_includes_negative_discount_line() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let coupons = [OrderCouponLine(couponID: 123, code: "5off", discount: "5.00", discountTax: "0.00")]
        let order = makeOrder(discountTotal: "5.00", coupons: coupons)

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let discountLine = content.cartTotals.first { $0.description.starts(with: expectedDiscountLineDescription()) }
        #expect(discountLine?.amount == "-5.00")
    }

    @Test func test_makeContent_when_order_has_no_discount_or_coupons_then_excludes_discount_line() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let order = makeOrder(discountTotal: "0.00", coupons: [])

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let discountLine = content.cartTotals.first { $0.description.starts(with: expectedDiscountLineDescription()) }
        #expect(discountLine == nil)
    }

    @Test func test_makeContent_when_order_has_coupon_without_discount_then_lists_coupon_with_zero_amount() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let coupons = [OrderCouponLine(couponID: 123, code: "FreeShipping", discount: "0.00", discountTax: "0.00")]
        let order = makeOrder(discountTotal: "0.00", coupons: coupons)

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let discountLine = try #require(content.cartTotals.first { $0.description.starts(with: expectedDiscountLineDescription()) })
        #expect(discountLine.description.contains("(FreeShipping)"))
        #expect(discountLine.amount == "0.00")
    }

    @Test func test_makeContent_when_order_has_multiple_coupons_then_lists_all_coupon_codes() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let coupons = [OrderCouponLine(couponID: 123, code: "1off", discount: "1.00", discountTax: "0.00"),
                       OrderCouponLine(couponID: 1901, code: "AVQW112", discount: "12.50", discountTax: "0.00")]
        let order = makeOrder(discountTotal: "13.50", coupons: coupons)

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let discountLine = try #require(content.cartTotals.first { $0.description.starts(with: expectedDiscountLineDescription()) })
        #expect(discountLine.description.contains("(1off, AVQW112)"))
    }

    // MARK: - Cart totals: fees

    @Test func test_makeContent_when_order_has_fees_then_includes_summed_fees_line() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let order = makeOrder(fees: [makeFee(amount: "5.00"), makeFee(amount: "15.50")])

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let feesLine = content.cartTotals.first { $0.description == ReceiptContent.Localization.feesLineDescription }
        #expect(feesLine?.amount == "$20.50")
    }

    @Test func test_makeContent_when_order_has_no_fees_then_excludes_fees_line() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let order = makeOrder(fees: [])

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let feesLine = content.cartTotals.first { $0.description == ReceiptContent.Localization.feesLineDescription }
        #expect(feesLine == nil)
    }

    @Test func test_makeContent_when_order_has_zero_fees_then_excludes_fees_line() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let order = makeOrder(fees: [makeFee(amount: "0.00")])

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let feesLine = content.cartTotals.first { $0.description == ReceiptContent.Localization.feesLineDescription }
        #expect(feesLine == nil)
    }

    // MARK: - Cart totals: line items total

    @Test func test_makeContent_then_line_items_total_uses_undiscounted_subtotals() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let items = [makeItem(subtotal: "20.00", total: "12.50"), makeItem(subtotal: "10.00", total: "10.00")]
        let order = makeOrder(items: items)

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let lineItemsTotalLine = content.cartTotals.first { $0.description == ReceiptContent.Localization.productTotalLineDescription }
        #expect(lineItemsTotalLine?.amount == "$30.00")
    }

    // MARK: - Amount paid

    @Test func test_makeContent_then_includes_amount_paid_line_from_parameters() throws {
        // Given
        let parameters = try makeReceiptParameters(amount: 10000)
        let order = makeOrder()

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters)

        // Then
        let amountPaidLine = content.cartTotals.first { $0.description == ReceiptContent.Localization.amountPaidLineDescription }
        #expect(amountPaidLine?.amount == "$100.00")
    }

    // MARK: - Order note

    @Test func test_makeContent_when_not_removing_html_then_order_note_is_unmodified() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let expectedNote = "<a href=\"https://example.com\">This note has a link</a>"
        let order = makeOrder(customerNote: expectedNote)

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters, removingHtml: false)

        // Then
        #expect(content.orderNote == expectedNote)
    }

    @Test func test_makeContent_when_removing_html_then_order_note_is_stripped() throws {
        // Given
        let parameters = try makeReceiptParameters()
        let order = makeOrder(customerNote: "<a href=\"https://example.com\">This note has a link</a>")

        // When
        let content = ReceiptContentAssembler().makeContent(order: order, parameters: parameters, removingHtml: true)

        // Then
        #expect(content.orderNote == "This note has a link")
    }
}

// MARK: - Test Data
private extension ReceiptContentAssemblerTests {
    static let cardPresentCharge = Charge.fake().copy(paymentMethod: .cardPresent(details: .fake()))

    func makeReceiptParameters(amount: UInt = 100) throws -> CardPresentReceiptParameters {
        let intent = PaymentIntent.fake().copy(amount: amount, charges: [Self.cardPresentCharge])
        return try #require(intent.receiptParameters())
    }

    func expectedDiscountLineDescription() -> String {
        String.localizedStringWithFormat(ReceiptContent.Localization.discountLineDescription, "")
    }

    func makeOrder(customerNote: String? = nil,
                   discountTotal: String = "",
                   discountTax: String = "",
                   shippingTotal: String = "",
                   shippingTax: String = "",
                   totalTax: String = "",
                   items: [Yosemite.OrderItem] = [],
                   coupons: [OrderCouponLine] = [],
                   fees: [Yosemite.OrderFeeLine] = [],
                   taxes: [Yosemite.OrderTaxLine] = []) -> Networking.Order {
        Order.fake().copy(siteID: 1234,
                          status: .custom(""),
                          currency: "usd",
                          customerNote: customerNote,
                          discountTotal: discountTotal,
                          discountTax: discountTax,
                          shippingTotal: shippingTotal,
                          shippingTax: shippingTax,
                          total: "100.00",
                          totalTax: totalTax,
                          items: items,
                          coupons: coupons,
                          fees: fees,
                          taxes: taxes)
    }

    func makeFee(id: Int64 = 123,
                 name: String = "Fee",
                 amount: String) -> Yosemite.OrderFeeLine {
        Yosemite.OrderFeeLine(feeID: id,
                              name: name,
                              taxClass: "",
                              taxStatus: .none,
                              total: amount,
                              totalTax: "0",
                              taxes: [],
                              attributes: [])
    }

    func makeItem(id: Int64 = 12345,
                  quantity: Decimal = Decimal(1),
                  price: NSDecimalNumber = NSDecimalNumber(10),
                  subtotal: String = "15",
                  total: String = "10") -> Yosemite.OrderItem {
        Yosemite.OrderItem(itemID: id,
                           name: "Product",
                           productID: 1234,
                           variationID: 123456,
                           quantity: quantity,
                           price: price,
                           sku: nil,
                           subtotal: subtotal,
                           subtotalTax: "",
                           taxClass: "",
                           taxes: [],
                           total: total,
                           totalTax: "",
                           attributes: [],
                           addOns: [],
                           image: nil,
                           parent: nil,
                           bundleConfiguration: [])
    }
}
