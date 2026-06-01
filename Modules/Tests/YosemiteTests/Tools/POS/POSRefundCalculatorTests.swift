import Testing
import Foundation
@testable import Yosemite

struct POSRefundCalculatorTests {
    private let sut = POSRefundCalculator()
    private let defaultDecimals = 2

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
