import Testing
import Foundation
@testable import Yosemite

struct POSRefundCalculatorTests {
    private let sut = POSRefundCalculator()
    private let defaultDecimals = 2

    // MARK: - Amount Calculation

    @Test func buildRefundRequest_when_multiple_items_then_calculates_correct_total_amount() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(10), totalTax: Decimal(1), originalQuantity: 1),
            POSRefundableItem(itemID: 2, lineItemTotal: Decimal(20), totalTax: Decimal(2), originalQuantity: 1)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.amount == Decimal(33))
    }

    @Test func buildRefundRequest_when_item_has_tax_then_includes_tax_in_amount() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(100), totalTax: Decimal(10), originalQuantity: 1)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.amount == Decimal(110))
    }

    @Test func buildRefundRequest_when_empty_items_then_returns_zero_amount() {
        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: [], reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.amount == Decimal.zero)
    }

    // MARK: - Order ID and Reason

    @Test func buildRefundRequest_then_sets_order_id_correctly() {
        // Given
        let orderID: Int64 = 456

        // When
        let request = sut.buildRefundRequest(orderID: orderID, selectedItems: [], reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.orderID == orderID)
    }

    @Test func buildRefundRequest_when_reason_provided_then_sets_reason_correctly() {
        // Given
        let reason = "Customer changed their mind"

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: [], reason: reason, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.reason == reason)
    }

    @Test func buildRefundRequest_when_reason_is_nil_then_returns_nil_reason() {
        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: [], reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.reason == nil)
    }

    // MARK: - Request Items

    @Test func buildRefundRequest_when_same_item_id_multiple_times_then_groups_into_single_item() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(30), totalTax: Decimal(6), originalQuantity: 3),
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(30), totalTax: Decimal(6), originalQuantity: 3)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.items.count == 1)
        #expect(request.items[0].quantity == 2)
        #expect(request.items[0].itemID == 1)
    }

    @Test func buildRefundRequest_when_different_item_ids_then_creates_separate_items() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(10), totalTax: Decimal(1), originalQuantity: 1),
            POSRefundableItem(itemID: 2, lineItemTotal: Decimal(20), totalTax: Decimal(2), originalQuantity: 1)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.items.count == 2)
    }

    @Test func buildRefundRequest_when_multiple_units_selected_then_calculates_refund_total_as_price_times_quantity() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(50), totalTax: Decimal(15), originalQuantity: 5),
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(50), totalTax: Decimal(15), originalQuantity: 5),
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(50), totalTax: Decimal(15), originalQuantity: 5)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.items[0].refundTotal == Decimal(30))
    }

    // MARK: - Tax Calculation

    @Test func buildRefundRequest_when_partial_units_selected_then_calculates_proportional_tax() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(40), totalTax: Decimal(4), originalQuantity: 4),
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(40), totalTax: Decimal(4), originalQuantity: 4)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.items[0].refundTax == Decimal(2))
    }

    @Test func buildRefundRequest_when_all_units_selected_then_uses_full_tax() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(20), totalTax: Decimal(5), originalQuantity: 2),
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(20), totalTax: Decimal(5), originalQuantity: 2)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.items[0].refundTax == Decimal(5))
    }

    // MARK: - Rounding

    @Test func buildRefundRequest_when_tax_requires_rounding_then_rounds_to_specified_decimals() {
        // Given: 3 units with total tax of 10, selecting 1 unit = 10/3 = 3.333...
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(30), totalTax: Decimal(10), originalQuantity: 3)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: 2)

        // Then: Should round 3.333... to 3.33
        #expect(request.items[0].refundTax == Decimal(string: "3.33"))
    }

    @Test func buildRefundRequest_when_tax_ends_in_half_cent_then_rounds_up() {
        // Given: 2 units with total tax of 1.05, selecting 1 unit = 1.05/2 = 0.525
        // Half-up rounding should round 0.525 to 0.53 (not 0.52 as banker's would)
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(10), totalTax: Decimal(string: "1.05")!, originalQuantity: 2)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: 2)

        // Then: Should round 0.525 up to 0.53 (half-up rounding)
        #expect(request.items[0].refundTax == Decimal(string: "0.53"))
    }

    @Test func buildRefundRequest_when_zero_original_quantity_then_returns_zero_tax() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(10), totalTax: Decimal(5), originalQuantity: 0)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.items[0].refundTax == Decimal.zero)
    }

    @Test func buildRefundRequest_when_three_decimals_configured_then_formats_to_three_decimals() {
        // Given: Price that requires 3 decimal precision
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(string: "10.555")!, totalTax: Decimal(string: "1.111")!, originalQuantity: 1)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: 3)

        // Then
        #expect(request.amount == Decimal(string: "11.666"))
    }

    // MARK: - Lump-sum lines (custom amounts / fees)

    @Test func buildRefundRequest_when_lump_sum_then_emits_quantity_zero() {
        // Given
        let items = [
            POSRefundableItem(itemID: 99, lineItemTotal: Decimal(15), totalTax: Decimal.zero, originalQuantity: 1, isLumpSum: true)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.items.count == 1)
        #expect(request.items[0].itemID == 99)
        #expect(request.items[0].quantity == 0)
        #expect(request.items[0].refundTotal == Decimal(15))
    }

    @Test func buildRefundRequest_when_lump_sum_with_tax_then_uses_full_tax() {
        // Given
        let items = [
            POSRefundableItem(itemID: 99, lineItemTotal: Decimal(20), totalTax: Decimal(2), originalQuantity: 1, isLumpSum: true)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.amount == Decimal(22))
        #expect(request.items[0].refundTax == Decimal(2))
    }

    @Test func buildRefundRequest_when_mixing_products_and_lump_sum_then_each_is_emitted_with_correct_quantity() throws {
        // Given
        let items = [
            // Two units of a product
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(50), totalTax: Decimal(5), originalQuantity: 2),
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(50), totalTax: Decimal(5), originalQuantity: 2),
            // One lump-sum fee
            POSRefundableItem(itemID: 99, lineItemTotal: Decimal(15), totalTax: Decimal.zero, originalQuantity: 1, isLumpSum: true)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil, numberOfDecimals: defaultDecimals)

        // Then
        #expect(request.items.count == 2)
        let product = try #require(request.items.first(where: { $0.itemID == 1 }))
        let fee = try #require(request.items.first(where: { $0.itemID == 99 }))
        #expect(product.quantity == 2)
        #expect(product.refundTotal == Decimal(50))
        #expect(fee.quantity == 0)
        #expect(fee.refundTotal == Decimal(15))
        #expect(request.amount == Decimal(70))
    }

    @Test func calculateRefundAmounts_when_lump_sum_then_uses_full_subtotal_and_tax() {
        // Given
        let items = [
            POSRefundableItem(itemID: 99, lineItemTotal: Decimal(15), totalTax: Decimal(1), originalQuantity: 1, isLumpSum: true)
        ]

        // When
        let amounts = sut.calculateRefundAmounts(for: items, numberOfDecimals: defaultDecimals)

        // Then
        #expect(amounts.subtotal == Decimal(15))
        #expect(amounts.tax == Decimal(1))
        #expect(amounts.total == Decimal(16))
    }
}
