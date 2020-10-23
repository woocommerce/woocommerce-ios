import XCTest
import Yosemite

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
}
