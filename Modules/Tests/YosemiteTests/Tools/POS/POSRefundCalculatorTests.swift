import Testing
import Foundation
@testable import Yosemite

struct POSRefundCalculatorTests {
    private let sut = POSRefundCalculator()

    // MARK: - Amount Calculation

    @Test func buildRefundRequest_when_multipleItems_then_calculatesCorrectTotalAmount() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(1), originalQuantity: 1),
            POSRefundableItem(itemID: 2, price: Decimal(20), totalTax: Decimal(2), originalQuantity: 1)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then
        // Total = (10 + 1) + (20 + 2) = 33
        #expect(request.amount == Decimal(33))
    }

    @Test func buildRefundRequest_when_itemHasTax_then_includesTaxInAmount() {
        // Given
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(100), totalTax: Decimal(10), originalQuantity: 1)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then
        #expect(request.amount == Decimal(110))
    }

    @Test func buildRefundRequest_when_emptyItems_then_returnsZeroAmount() {
        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: [], reason: nil)

        // Then
        #expect(request.amount == Decimal.zero)
    }

    // MARK: - Order ID and Reason

    @Test func buildRefundRequest_then_setsOrderIDCorrectly() {
        // Given
        let orderID: Int64 = 456

        // When
        let request = sut.buildRefundRequest(orderID: orderID, selectedItems: [], reason: nil)

        // Then
        #expect(request.orderID == orderID)
    }

    @Test func buildRefundRequest_when_reasonProvided_then_setsReasonCorrectly() {
        // Given
        let reason = "Customer changed their mind"

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: [], reason: reason)

        // Then
        #expect(request.reason == reason)
    }

    @Test func buildRefundRequest_when_reasonIsNil_then_returnsNilReason() {
        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: [], reason: nil)

        // Then
        #expect(request.reason == nil)
    }

    // MARK: - Request Items

    @Test func buildRefundRequest_when_sameItemIDMultipleTimes_then_groupsIntoSingleItem() {
        // Given - two items with same itemID (representing 2 units of same product)
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(2), originalQuantity: 3),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(2), originalQuantity: 3)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then - should be grouped into one request item with quantity 2
        #expect(request.items.count == 1)
        #expect(request.items[0].quantity == 2)
        #expect(request.items[0].itemID == 1)
    }

    @Test func buildRefundRequest_when_differentItemIDs_then_createsSeparateItems() {
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

    @Test func buildRefundRequest_when_multipleUnitsSelected_then_calculatesRefundTotalAsPriceTimesQuantity() {
        // Given - 3 units of same item selected
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(3), originalQuantity: 5),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(3), originalQuantity: 5),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(3), originalQuantity: 5)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then - refundTotal = 10 * 3 = 30
        #expect(request.items[0].refundTotal == Decimal(30))
    }

    // MARK: - Tax Calculation

    @Test func buildRefundRequest_when_partialUnitsSelected_then_calculatesProportionalTax() {
        // Given - 2 out of 4 units selected (originalQuantity = 4, totalTax = 4)
        // Expected tax = (4 / 4) * 2 = 2
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(4), originalQuantity: 4),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(4), originalQuantity: 4)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then - refundTax = (4 / 4) * 2 = 2
        #expect(request.items[0].refundTax == Decimal(2))
    }

    @Test func buildRefundRequest_when_allUnitsSelected_then_usesFullTax() {
        // Given - all 2 units selected (originalQuantity = 2, totalTax = 5)
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(5), originalQuantity: 2),
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(5), originalQuantity: 2)
        ]

        // When
        let request = sut.buildRefundRequest(orderID: 123, selectedItems: items, reason: nil)

        // Then - full tax amount since all units selected
        #expect(request.items[0].refundTax == Decimal(5))
    }
}
