import Testing
import Foundation
@testable import Yosemite

struct POSRefundCalculatorTests {
    private let sut = POSRefundCalculator()

    // MARK: - Amount Calculation

    @Test func buildRefundRequest_when_multiple_items_then_calculates_correct_total_amount() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(1), originalQuantity: 1),
            POSRefundableItem(itemID: 2, price: Decimal(20), totalTax: Decimal(2), originalQuantity: 1)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then
        #expect(request.amount == Decimal(33))
    }

    @Test func buildRefundRequest_when_item_has_tax_then_includes_tax_in_amount() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(100), totalTax: Decimal(10), originalQuantity: 1)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then
        #expect(request.amount == Decimal(110))
    }

    @Test func buildRefundRequest_when_empty_items_then_returns_zero_amount() {
        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: [], reason: nil)

        // Then
        #expect(request.amount == Decimal.zero)
    }

    // MARK: - Order ID and Reason

    @Test func buildRefundRequest_then_sets_order_id_correctly() {
        // Given
        let orderID: Int64 = 456

        // When
        let request = sut.buildRefundRequest(orderID: orderID, selectedItems: [], reason: nil)

        // Then
        #expect(request.orderID == orderID)
    }

    @Test func buildRefundRequest_when_reason_provided_then_sets_reason_correctly() {
        // Given
        let reason = "Customer changed their mind"

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: [], reason: reason)

        // Then
        #expect(request.reason == reason)
    }

    @Test func buildRefundRequest_when_reason_is_nil_then_returns_nil_reason() {
        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: [], reason: nil)

        // Then
        #expect(request.reason == nil)
    }

    // MARK: - Request Items

    @Test func buildRefundRequest_when_same_item_id_multiple_times_then_groups_into_single_item() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(2), originalQuantity: 3),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(2), originalQuantity: 3)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then
        #expect(request.items.count == 1)
        #expect(request.items[0].quantity == 2)
        #expect(request.items[0].itemID == 1)
    }

    @Test func buildRefundRequest_when_different_item_ids_then_creates_separate_items() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(1), originalQuantity: 1),
            POSRefundableItem(itemID: 2, price: Decimal(20), totalTax: Decimal(2), originalQuantity: 1)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then
        #expect(request.items.count == 2)
    }

    @Test func buildRefundRequest_when_multiple_units_selected_then_calculates_refund_total_as_price_times_quantity() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(3), originalQuantity: 5),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(3), originalQuantity: 5),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(3), originalQuantity: 5)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then
        #expect(request.items[0].refundTotal == Decimal(30))
    }

    // MARK: - Tax Calculation

    @Test func buildRefundRequest_when_partial_units_selected_then_calculates_proportional_tax() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(4), originalQuantity: 4),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(4), originalQuantity: 4)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then
        #expect(request.items[0].refundTax == Decimal(2))
    }

    @Test func buildRefundRequest_when_all_units_selected_then_uses_full_tax() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(5), originalQuantity: 2),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(5), originalQuantity: 2)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then
        #expect(request.items[0].refundTax == Decimal(5))
    }
}
