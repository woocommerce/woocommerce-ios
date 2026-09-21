import XCTest
import Yosemite
import WooFoundation

@testable import WooCommerce

/// Test cases for `RefundShippingCalculationUseCase`
///
final class RefundShippingCalculationUseCaseTests: XCTestCase {
    func test_useCase_correctly_calculates_total_from_shipping_line_without_taxes() {
        // Given
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let shippingLine = ShippingLine(shippingID: 123, methodTitle: "", methodID: "", total: "12.40", totalTax: "0.0", taxes: [])

        // When
        let useCase = RefundShippingCalculationUseCase(shippingLine: shippingLine, currencyFormatter: formatter)
        let value = useCase.calculateRefundValue()

        XCTAssertEqual(value, 12.40)
    }

    func test_useCase_correctly_calculates_total_from_shipping_line_with_taxes() {
        // Given
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let shippingLine = ShippingLine(shippingID: 123, methodTitle: "", methodID: "", total: "12.40", totalTax: "1.99", taxes: [])

        // When
        let useCase = RefundShippingCalculationUseCase(shippingLine: shippingLine, currencyFormatter: formatter)
        let value = useCase.calculateRefundValue()

        XCTAssertEqual(value, 14.39)
    }

    func test_calculateRefundValue_when_totalTax_is_rounded_to_currency_decimals_then_tax_is_summed_from_tax_lines() {
        // Given
        // Values from a $1.00 tax-inclusive shipping charge with a 13% rate and WooCommerce's default
        // "round tax per line" setting: `totalTax` is rounded to currency decimals while
        // `total` and `taxes[].total` keep the API's full precision.
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let shippingLine = ShippingLine(shippingID: 123,
                                        methodTitle: "",
                                        methodID: "",
                                        total: "0.884956",
                                        totalTax: "0.12",
                                        taxes: [ShippingLineTax(taxID: 1, subtotal: "", total: "0.115044")])

        // When
        let useCase = RefundShippingCalculationUseCase(shippingLine: shippingLine, currencyFormatter: formatter)
        let value = useCase.calculateRefundValue()

        // Then
        // Summing `total` + `totalTax` would yield 1.004956, above the 1.00 gross value of the line.
        XCTAssertEqual(value, Decimal(string: "1.00"))
    }
}
