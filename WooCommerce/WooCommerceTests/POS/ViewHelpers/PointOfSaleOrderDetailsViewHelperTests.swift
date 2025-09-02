import Foundation
import Testing
@testable import WooCommerce
import Yosemite
import WooFoundation

struct PointOfSaleOrderDetailsViewHelperTests {
    private let mockCurrencySettings: CurrencySettings
    private let sut: PointOfSaleOrderDetailsViewHelper

    init() {
        mockCurrencySettings = CurrencySettings()
        sut = PointOfSaleOrderDetailsViewHelper(currencySettings: mockCurrencySettings)
    }

    // MARK: - Products Subtotal Tests

    @Test func productsSubtotal_emptyLineItems_returnZero() async throws {
        // Given
        let order = makePOSOrder(lineItems: [])

        // When
        let result = sut.productsSubtotal(for: order)

        // Then
        #expect(result == "$0.00")
    }

    @Test func productsSubtotal_singleItem_returnsFormattedSubtotal() async throws {
        // Given
        let item = makePOSOrderItem(subtotal: "25.00")
        let order = makePOSOrder(lineItems: [item])

        // When
        let result = sut.productsSubtotal(for: order)

        // Then
        #expect(result == "$25.00")
    }

    @Test func productsSubtotal_multipleItems_returnsSummedSubtotal() async throws {
        // Given
        let item1 = makePOSOrderItem(subtotal: "25.00")
        let item2 = makePOSOrderItem(subtotal: "15.99")
        let order = makePOSOrder(lineItems: [item1, item2])

        // When
        let result = sut.productsSubtotal(for: order)

        // Then
        #expect(result == "$40.99")
    }

    @Test func productsSubtotal_invalidSubtotalString_treatAsZero() async throws {
        // Given
        let item1 = makePOSOrderItem(subtotal: "invalid")
        let item2 = makePOSOrderItem(subtotal: "10.00")
        let order = makePOSOrder(lineItems: [item1, item2])

        // When
        let result = sut.productsSubtotal(for: order)

        // Then
        #expect(result == "$10.00")
    }

    // MARK: - Should Show Products Subtotal Tests

    @Test func shouldShowProductsSubtotal_emptyLineItems_returnsFalse() async throws {
        // Given
        let order = makePOSOrder(lineItems: [])

        // When
        let result = sut.shouldShowProductsSubtotal(for: order)

        // Then
        #expect(result == false)
    }

    @Test func shouldShowProductsSubtotal_hasLineItems_returnsTrue() async throws {
        // Given
        let item = makePOSOrderItem()
        let order = makePOSOrder(lineItems: [item])

        // When
        let result = sut.shouldShowProductsSubtotal(for: order)

        // Then
        #expect(result == true)
    }

    // MARK: - Net Payment After Refunds Tests

    @Test func netPaymentAfterRefunds_noRefunds_returnsEmptyString() async throws {
        // Given
        let order = makePOSOrder(total: "100.00", refunds: [])

        // When
        let result = sut.netPaymentAfterRefunds(for: order)

        // Then
        #expect(result == "")
    }

    @Test func netPaymentAfterRefunds_singleRefund_returnsNetAmount() async throws {
        // Given
        let refund = makePOSOrderRefund(total: "-20.00")
        let order = makePOSOrder(total: "100.00", refunds: [refund])

        // When
        let result = sut.netPaymentAfterRefunds(for: order)

        // Then
        #expect(result == "$80.00")
    }

    @Test func netPaymentAfterRefunds_multipleRefunds_returnsNetAmount() async throws {
        // Given
        let refund1 = makePOSOrderRefund(total: "-20.00")
        let refund2 = makePOSOrderRefund(total: "-15.50")
        let order = makePOSOrder(total: "100.00", refunds: [refund1, refund2])

        // When
        let result = sut.netPaymentAfterRefunds(for: order)

        // Then
        #expect(result == "$64.50")
    }

    @Test func netPaymentAfterRefunds_positiveRefundValue_treatsAsAbsolute() async throws {
        // Given - Some data might have positive refund values
        let refund = makePOSOrderRefund(total: "20.00")
        let order = makePOSOrder(total: "100.00", refunds: [refund])

        // When
        let result = sut.netPaymentAfterRefunds(for: order)

        // Then
        #expect(result == "$80.00")
    }

    @Test func netPaymentAfterRefunds_invalidRefundString_treatAsZero() async throws {
        // Given
        let refund = makePOSOrderRefund(total: "invalid")
        let order = makePOSOrder(total: "100.00", refunds: [refund])

        // When
        let result = sut.netPaymentAfterRefunds(for: order)

        // Then
        #expect(result == "$100.00")
    }

    // MARK: - Should Show Net Payment Tests

    @Test func shouldShowNetPayment_noRefunds_returnsFalse() async throws {
        // Given
        let order = makePOSOrder(refunds: [])

        // When
        let result = sut.shouldShowNetPayment(for: order)

        // Then
        #expect(result == false)
    }

    @Test func shouldShowNetPayment_hasRefunds_returnsTrue() async throws {
        // Given
        let refund = makePOSOrderRefund()
        let order = makePOSOrder(refunds: [refund])

        // When
        let result = sut.shouldShowNetPayment(for: order)

        // Then
        #expect(result == true)
    }

    // MARK: - Discount Total Tests

    @Test func formattedDiscountTotal_zeroDiscount_returnsNil() async throws {
        // Given
        let order = makePOSOrder(discountTotal: "0.00")

        // When
        let result = sut.formattedDiscountTotal(for: order)

        // Then
        #expect(result == nil)
    }

    @Test func formattedDiscountTotal_positiveDiscount_returnsFormattedAmount() async throws {
        // Given
        let order = makePOSOrder(discountTotal: "15.50")

        // When
        let result = sut.formattedDiscountTotal(for: order)

        // Then
        #expect(result == "-$15.50")
    }

    // MARK: - Should Show Discount Tests

    @Test func shouldShowDiscount_zeroDiscount_returnsFalse() async throws {
        // Given
        let order = makePOSOrder(discountTotal: "0.00")

        // When
        let result = sut.shouldShowDiscount(for: order)

        // Then
        #expect(result == false)
    }

    @Test func shouldShowDiscount_positiveDiscount_returnsTrue() async throws {
        // Given
        let order = makePOSOrder(discountTotal: "15.50")

        // When
        let result = sut.shouldShowDiscount(for: order)

        // Then
        #expect(result == true)
    }

    // MARK: - Tax Total Tests

    @Test func formattedTaxTotal_zeroTax_returnsNil() async throws {
        // Given
        let order = makePOSOrder(totalTax: "0.00")

        // When
        let result = sut.formattedTaxTotal(for: order)

        // Then
        #expect(result == nil)
    }

    @Test func formattedTaxTotal_positiveTax_returnsFormattedAmount() async throws {
        // Given
        let order = makePOSOrder(totalTax: "8.25")

        // When
        let result = sut.formattedTaxTotal(for: order)

        // Then
        #expect(result == "$8.25")
    }

    // MARK: - Formatted Order Total Tests

    @Test func formattedOrderTotal_validTotal_returnsFormattedAmount() async throws {
        // Given
        let order = makePOSOrder(total: "89.50")

        // When
        let result = sut.formattedOrderTotal(for: order)

        // Then
        #expect(result == "$89.50")
    }

    @Test func formattedOrderTotal_zeroTotal_returnsFormattedZero() async throws {
        // Given
        let order = makePOSOrder(total: "0.00")

        // When
        let result = sut.formattedOrderTotal(for: order)

        // Then
        #expect(result == "$0.00")
    }

    // MARK: - Formatted Paid Amount Tests

    @Test func formattedPaidAmount_noPaidDate_returnsZero() async throws {
        // Given
        let order = makePOSOrder(datePaid: nil, total: "89.50")

        // When
        let result = sut.formattedPaidAmount(for: order)

        // Then
        #expect(result == "$0.00")
    }

    @Test func formattedPaidAmount_hasPaidDate_returnsOrderTotal() async throws {
        // Given
        let order = makePOSOrder(datePaid: Date(), total: "89.50")

        // When
        let result = sut.formattedPaidAmount(for: order)

        // Then
        #expect(result == "$89.50")
    }

    // MARK: - Formatted Refund Total Tests

    @Test func formattedRefundTotal_validRefundAmount_returnsFormattedAmount() async throws {
        // Given
        let refund = makePOSOrderRefund(total: "-19.99")

        // When
        let result = sut.formattedRefundTotal(refund, currency: "USD")

        // Then
        #expect(result == "-$19.99")
    }

    @Test func formattedRefundTotal_positiveAmount_returnsFormattedAmount() async throws {
        // Given
        let refund = makePOSOrderRefund(total: "19.99")

        // When
        let result = sut.formattedRefundTotal(refund, currency: "USD")

        // Then
        #expect(result == "$19.99")
    }

    // MARK: - Format Item Price Tests

    @Test func formatItemPrice_validDecimal_returnsFormattedPrice() async throws {
        // Given
        let price = NSDecimalNumber(string: "12.50")

        // When
        let result = sut.formatItemPrice(price, with: "USD")

        // Then
        #expect(result == "$12.50")
    }

    @Test func formatItemPrice_zeroPrice_returnsFormattedZero() async throws {
        // Given
        let price = NSDecimalNumber.zero

        // When
        let result = sut.formatItemPrice(price, with: "USD")

        // Then
        #expect(result == "$0.00")
    }

    // MARK: - Format Item Total Tests

    @Test func formatItemTotal_validTotal_returnsFormattedAmount() async throws {
        // Given
        let total = "25.00"

        // When
        let result = sut.formatItemTotal(total, with: "USD")

        // Then
        #expect(result == "$25.00")
    }

    @Test func formatItemTotal_zeroTotal_returnsFormattedZero() async throws {
        // Given
        let total = "0.00"

        // When
        let result = sut.formatItemTotal(total, with: "USD")

        // Then
        #expect(result == "$0.00")
    }

    // MARK: - Edge Cases and Error Handling Tests

    @Test func productsSubtotal_decimalPrecision_maintainsPrecision() async throws {
        // Given
        mockCurrencySettings.fractionDigits = 3
        let item1 = makePOSOrderItem(subtotal: "12.345")
        let item2 = makePOSOrderItem(subtotal: "7.654")
        let order = makePOSOrder(lineItems: [item1, item2])

        // When
        let result = sut.productsSubtotal(for: order)

        // Then
        #expect(result == "$19.999")
    }

    @Test func netPaymentAfterRefunds_largeNumbers_handlesCorrectly() async throws {
        // Given
        let refund1 = makePOSOrderRefund(total: "-999.99")
        let refund2 = makePOSOrderRefund(total: "-500.01")
        let order = makePOSOrder(total: "2000.00", refunds: [refund1, refund2])

        // When
        let result = sut.netPaymentAfterRefunds(for: order)

        // Then
        #expect(result == "$500.00")
    }
}

// MARK: - Test Helper Methods

private func makePOSOrder(
    id: Int64 = 1,
    number: String = "1001",
    dateCreated: Date = Date(),
    datePaid: Date? = Date(),
    status: OrderStatusEnum = .completed,
    total: String = "100.00",
    customerEmail: String? = "test@example.com",
    paymentMethodID: String = "cod",
    paymentMethodTitle: String = "Cash on Delivery",
    lineItems: [POSOrderItem] = [],
    refunds: [POSOrderRefund] = [],
    currency: String = "USD",
    currencySymbol: String = "$",
    discountTotal: String = "0.00",
    totalTax: String = "0.00"
) -> POSOrder {
    POSOrder(
        id: id,
        number: number,
        dateCreated: dateCreated,
        datePaid: datePaid,
        status: status,
        total: total,
        customerEmail: customerEmail,
        paymentMethodID: paymentMethodID,
        paymentMethodTitle: paymentMethodTitle,
        lineItems: lineItems,
        refunds: refunds,
        currency: currency,
        currencySymbol: currencySymbol,
        discountTotal: discountTotal,
        totalTax: totalTax
    )
}

private func makePOSOrderItem(
    itemID: Int64 = 1,
    name: String = "Test Item",
    productID: Int64 = 101,
    variationID: Int64 = 0,
    quantity: Decimal = 1.0,
    price: NSDecimalNumber = NSDecimalNumber(string: "10.00"),
    subtotal: String = "10.00",
    total: String = "10.00",
    attributes: [OrderItemAttribute] = []
) -> POSOrderItem {
    POSOrderItem(
        itemID: itemID,
        name: name,
        productID: productID,
        variationID: variationID,
        quantity: quantity,
        price: price,
        subtotal: subtotal,
        total: total,
        attributes: attributes
    )
}

private func makePOSOrderRefund(
    refundID: Int64 = 1,
    total: String = "-10.00",
    reason: String? = "Test refund"
) -> POSOrderRefund {
    POSOrderRefund(
        refundID: refundID,
        total: total,
        reason: reason
    )
}
