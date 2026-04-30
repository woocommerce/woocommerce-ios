import Foundation
import Testing
import WooFoundation
import NetworkingCore
@testable import Yosemite

struct POSOrderMapperTests {
    private let currencyFormatter: CurrencyFormatter
    private let sut: POSOrderMapper

    init() {
        currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        sut = POSOrderMapper(currencyFormatter: currencyFormatter)
    }

    // MARK: - formattedDiscountTotal Logic Tests

    @Test
    func formattedDiscountTotal_returns_nil_when_discount_total_is_zero() throws {
        // Given
        let order = makeOrder(discountTotal: "0.00")

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedDiscountTotal == nil)
    }

    @Test
    func formattedDiscountTotal_returns_nil_when_discount_total_is_negative() throws {
        // Given
        let order = makeOrder(discountTotal: "-5.00")

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedDiscountTotal == nil)
    }

    @Test
    func formattedDiscountTotal_returns_nil_when_discount_total_is_invalid() throws {
        // Given
        let order = makeOrder(discountTotal: "invalid")

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedDiscountTotal == nil)
    }

    @Test
    func formattedDiscountTotal_returns_formatted_negative_value_when_discount_total_is_positive() throws {
        // Given
        let order = makeOrder(discountTotal: "15.50", currency: "USD")

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedDiscountTotal == "-$15.50")
    }

    // MARK: - formattedPaymentTotal Logic Tests

    @Test
    func formattedPaymentTotal_returns_zero_when_order_is_not_paid() throws {
        // Given
        let order = makeOrder(total: "25.99", datePaid: nil, currency: "USD")

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedPaymentTotal == "$0.00")
    }

    @Test
    func formattedPaymentTotal_returns_total_value_when_order_is_paid() throws {
        // Given
        let order = makeOrder(total: "25.99", datePaid: Date(), currency: "USD")

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedPaymentTotal == "$25.99")
    }

    // MARK: - formattedNetAmount Logic Tests

    @Test
    func formattedNetAmount_returns_nil_when_no_refunds_exist() throws {
        // Given
        let order = makeOrder(total: "25.99", currency: "USD", refunds: [])

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedNetAmount == nil)
    }

    @Test
    func formattedNetAmount_returns_calculated_net_amount_when_refunds_exist() throws {
        // Given
        let refund = makeRefund(refundID: 1, total: "-10.00")
        let order = makeOrder(total: "25.99", currency: "USD", refunds: [refund])

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedNetAmount == "$15.99")
    }

    @Test
    func formattedNetAmount_returns_zero_when_refund_equals_total() throws {
        // Given
        let refund = makeRefund(refundID: 1, total: "-25.99")
        let order = makeOrder(total: "25.99", currency: "USD", refunds: [refund])

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedNetAmount == "$0.00")
    }

    @Test
    func formattedNetAmount_handles_multiple_refunds() throws {
        // Given
        let refund1 = makeRefund(refundID: 1, total: "-10.00")
        let refund2 = makeRefund(refundID: 2, total: "-5.00")
        let order = makeOrder(total: "25.99", currency: "USD", refunds: [refund1, refund2])

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.formattedNetAmount == "$10.99")
    }

    // MARK: - Custom Amounts

    @Test
    func customAmounts_are_mapped_from_active_order_fees() throws {
        // Given
        let fee = OrderFeeLine.fake().copy(feeID: 42, name: "Service fee", total: "10.00")
        let order = makeOrder(currency: "USD", fees: [fee])

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.customAmounts.count == 1)
        let mapped = try #require(result.customAmounts.first)
        #expect(mapped.id == 42)
        #expect(mapped.name == "Service fee")
        #expect(mapped.formattedTotal == "$10.00")
    }

    @Test
    func customAmounts_skip_deleted_fee_lines() throws {
        // Given
        let liveFee = OrderFeeLine.fake().copy(feeID: 1, name: "Tip", total: "5.00")
        let deletedFee = OrderFactory.deletedFeeLine(OrderFeeLine.fake().copy(feeID: 2, name: "Removed", total: "8.00"))
        let order = makeOrder(currency: "USD", fees: [liveFee, deletedFee])

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.customAmounts.count == 1)
        #expect(result.customAmounts.first?.name == "Tip")
    }

    @Test
    func customAmounts_use_default_name_when_fee_line_has_no_name() throws {
        // Given
        let fee = OrderFeeLine.fake().copy(feeID: 1, name: nil, total: "3.00")
        let order = makeOrder(currency: "USD", fees: [fee])

        // When
        let result = try sut.map(order: order)

        // Then - falls back to a localized "Custom amount" placeholder so the row
        // never renders with empty left-side text.
        #expect(result.customAmounts.first?.name == "Custom amount")
    }

    @Test
    func customAmounts_use_default_name_when_fee_line_name_is_blank() throws {
        // Given
        let fee = OrderFeeLine.fake().copy(feeID: 1, name: "   ", total: "3.00")
        let order = makeOrder(currency: "USD", fees: [fee])

        // When
        let result = try sut.map(order: order)

        // Then
        #expect(result.customAmounts.first?.name == "Custom amount")
    }
}

// MARK: - Test Helpers

private extension POSOrderMapperTests {
    func makeOrder(
        orderID: Int64 = 1,
        number: String = "1001",
        dateCreated: Date = Date(),
        status: OrderStatusEnum = .completed,
        total: String = "25.99",
        datePaid: Date? = nil,
        discountTotal: String = "0.00",
        totalTax: String = "2.50",
        currency: String = "USD",
        refunds: [OrderRefundCondensed] = [],
        items: [OrderItem] = [],
        fees: [OrderFeeLine] = []
    ) -> NetworkingCore.Order {
        return NetworkingCore.Order.fake().copy(
            orderID: orderID,
            number: number,
            status: status,
            currency: currency,
            dateCreated: dateCreated,
            datePaid: datePaid,
            discountTotal: discountTotal,
            total: total,
            totalTax: totalTax,
            items: items.isEmpty ? [makeOrderItem()] : items,
            refunds: refunds,
            fees: fees
        )
    }

    func makeOrderItem(
        itemID: Int64 = 1,
        name: String = "Test Item",
        productID: Int64 = 101,
        variationID: Int64 = 0,
        quantity: Decimal = 1.0,
        price: NSDecimalNumber = NSDecimalNumber(string: "10.00"),
        subtotal: String = "10.00",
        total: String = "10.00",
        totalTax: String = "0.00"
    ) -> NetworkingCore.OrderItem {
        return NetworkingCore.OrderItem.fake().copy(
            itemID: itemID,
            name: name,
            productID: productID,
            variationID: variationID,
            quantity: quantity,
            price: price,
            subtotal: subtotal,
            total: total,
            totalTax: totalTax,
            image: nil
        )
    }

    func makeRefund(
        refundID: Int64,
        total: String,
        reason: String? = nil
    ) -> NetworkingCore.OrderRefundCondensed {
        return NetworkingCore.OrderRefundCondensed(
            refundID: refundID,
            reason: reason,
            total: total
        )
    }
}
