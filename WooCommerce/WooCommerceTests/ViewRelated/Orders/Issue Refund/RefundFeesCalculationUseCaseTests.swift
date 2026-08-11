import Foundation
import Testing
import Yosemite
import WooFoundation

@testable import WooCommerce

/// Test cases for `RefundFeesCalculationUseCase`
///
struct RefundFeesCalculationUseCaseTests {
    @Test func test_calculateRefundValues_when_fees_have_no_tax_lines_then_totalTax_is_used() {
        // Given
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let fees = [
            OrderFeeLine.fake().copy(total: "10.00", totalTax: "1.15", taxes: []),
            OrderFeeLine.fake().copy(total: "5.00", totalTax: "0.50", taxes: [])
        ]

        // When
        let useCase = RefundFeesCalculationUseCase(fees: fees, currencyFormatter: formatter)
        let values = useCase.calculateRefundValues()

        // Then
        #expect(values.subtotal == 15.00)
        #expect(values.tax == 1.65)
        #expect(values.total == 16.65)
    }

    @Test func test_calculateRefundValues_when_totalTax_is_rounded_to_currency_decimals_then_tax_is_summed_from_tax_lines() {
        // Given
        // Values from a $1.00 tax-inclusive fee with a 13% rate and WooCommerce's default
        // "round tax per line" setting: `totalTax` is rounded to currency decimals while
        // `total` and `taxes[].total` keep the API's full precision.
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let fees = [
            OrderFeeLine.fake().copy(total: "0.884956",
                                     totalTax: "0.12",
                                     taxes: [OrderItemTax(taxID: 1, subtotal: "", total: "0.115044")])
        ]

        // When
        let useCase = RefundFeesCalculationUseCase(fees: fees, currencyFormatter: formatter)
        let values = useCase.calculateRefundValues()

        // Then
        // Summing `total` + `totalTax` would yield 1.004956, above the 1.00 gross value of the fee.
        #expect(values.tax == Decimal(string: "0.115044"))
        #expect(values.total == Decimal(string: "1.00"))
    }
}
