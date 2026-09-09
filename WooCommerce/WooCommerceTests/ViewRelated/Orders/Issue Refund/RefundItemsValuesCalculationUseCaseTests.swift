import XCTest
import Yosemite
import WooFoundation

@testable import WooCommerce

/// Test cases for `RefundItemsValuesCalculationUseCase`
///
final class RefundItemsValuesCalculationUseCaseTests: XCTestCase {
    func test_useCase_correctly_calculates_values_from_regular_items() {
        // Given
        let item1Price: Decimal = 10.50
        let item1Quantity: Decimal  = 1

        let item2Price: Decimal = 15.00
        let item2Quantity: Decimal  = 2

        let item3Price: Decimal  = 7.99
        let item3Quantity: Decimal  = 3


        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())

        let refundItems: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(quantity: item1Quantity,
                                                 total: formatter.localize(item1Price * item1Quantity) ?? "0",
                                                 totalTax: "1.20"),
                  quantity: 1),
            .init(item: MockOrderItem.sampleItem(quantity: item2Quantity,
                                                 total: formatter.localize(item2Price * item2Quantity) ?? "0",
                                                 totalTax: "4.20"),
                  quantity: 2),
            .init(item: MockOrderItem.sampleItem(quantity: item3Quantity,
                                                 total: formatter.localize(item3Price * item3Quantity) ?? "0",
                                                 totalTax: "3.30"),
                  quantity: 2),
        ]

        // When
        let useCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: formatter)
        let values = useCase.calculateRefundValues()

        // Then
        // Subtotal = 1 x 10.50(item1 price) + 2 x 15.00(item2 price) + 2 * 7.99(item3 price) = 56.48
        // Tax = 1 x 1.28(item1 tax) + 2 x 1.10(item2 tax) + 2 * 1.10(item3 tax) = 7.60
        XCTAssertEqual(values.subtotal, 56.48)
        XCTAssertEqual(values.tax, 7.60)
        XCTAssertEqual(values.total, 64.08)
    }

    func test_useCase_correctly_ignores_0_quantity_values() {
        // Given
        let item1Price: Decimal = 10.50
        let item1Quantity: Decimal  = 1

        let item2Price: Decimal = 15.00
        let item2Quantity: Decimal  = 2

        let item3Price: Decimal  = 7.99
        let item3Quantity: Decimal  = 3


        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())

        let refundItems: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(quantity: item1Quantity,
                                                 total: formatter.localize(item1Price * item1Quantity) ?? "0",
                                                 totalTax: "1.20"),
                  quantity: 1),
            .init(item: MockOrderItem.sampleItem(quantity: item2Quantity,
                                                 total: formatter.localize(item2Price * item2Quantity) ?? "0",
                                                 totalTax: "4.20"),
                  quantity: 0),
            .init(item: MockOrderItem.sampleItem(quantity: item3Quantity,
                                                 total: formatter.localize(item3Price * item3Quantity) ?? "0",
                                                 totalTax: "3.30"),
                  quantity: 0),
        ]


        // When
        let useCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: formatter)
        let values = useCase.calculateRefundValues()

        // Then
        XCTAssertEqual(values.subtotal, 10.50)
        XCTAssertEqual(values.tax, 1.20)
        XCTAssertEqual(values.total, 11.70)
    }

    func test_useCase_correctly_calculates_no_items() {
        // Given
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let refundItems: [RefundableOrderItem] = []

        // When
        let useCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: formatter)
        let values = useCase.calculateRefundValues()

        // Then
        XCTAssertEqual(values.subtotal, 0.0)
        XCTAssertEqual(values.tax, 0.0)
        XCTAssertEqual(values.total, 0.0)
    }

    func test_calculateRefundValues_when_totalTax_is_rounded_to_currency_decimals_then_tax_is_summed_from_tax_lines() {
        // Given
        // Values from a $1.00 tax-inclusive item with a 13% rate and WooCommerce's default
        // "round tax per line" setting: `totalTax` is rounded to currency decimals while
        // `total` and `taxes[].total` keep the API's full precision.
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let refundItems: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(quantity: 1,
                                                 taxes: [OrderItemTax(taxID: 1, subtotal: "", total: "0.115044")],
                                                 total: "0.884956",
                                                 totalTax: "0.12"),
                  quantity: 1)
        ]

        // When
        let useCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: formatter)
        let values = useCase.calculateRefundValues()

        // Then
        // Summing `total` + `totalTax` would yield 1.004956, above the 1.00 order total.
        XCTAssertEqual(values.tax, Decimal(string: "0.115044"))
        XCTAssertEqual(values.total, Decimal(string: "1.00"))
    }

    func test_calculateRefundValues_when_item_has_multiple_tax_lines_then_tax_lines_are_summed_for_partial_quantities() {
        // Given
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let refundItems: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(quantity: 2,
                                                 taxes: [OrderItemTax(taxID: 1, subtotal: "", total: "0.30"),
                                                         OrderItemTax(taxID: 2, subtotal: "", total: "0.10")],
                                                 total: "10.00",
                                                 totalTax: "0.40"),
                  quantity: 1)
        ]

        // When
        let useCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: formatter)
        let values = useCase.calculateRefundValues()

        // Then
        // Tax = (0.30 + 0.10) / 2 (purchased quantity) x 1 (refunded quantity) = 0.20
        XCTAssertEqual(values.subtotal, 5.00)
        XCTAssertEqual(values.tax, 0.20)
    }

    func test_calculateRefundValues_when_item_has_no_tax_lines_then_totalTax_is_used() {
        // Given
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let refundItems: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(quantity: 2,
                                                 total: "10.00",
                                                 totalTax: "0.50"),
                  quantity: 1)
        ]

        // When
        let useCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: formatter)
        let values = useCase.calculateRefundValues()

        // Then
        XCTAssertEqual(values.subtotal, 5.00)
        XCTAssertEqual(values.tax, 0.25)
    }
}
