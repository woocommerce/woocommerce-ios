import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `RefundItemsValuesCalculationUseCase`
///
final class RefundItemsValuesCalculationUseCaseTests: XCTestCase {
    func test_useCase_correctly_calculates_values_from_regular_items() {
        // Given
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let refundItems: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(quantity: 1, price: 10.50, totalTax: "1.20"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(quantity: 2, price: 15.00, totalTax: "4.20"), quantity: 2),
            .init(item: MockOrderItem.sampleItem(quantity: 3, price: 7.99, totalTax: "3.30"), quantity: 2),
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
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let refundItems: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(quantity: 1, price: 10.50, totalTax: "1.20"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(quantity: 2, price: 15.00, totalTax: "4.20"), quantity: 0),
            .init(item: MockOrderItem.sampleItem(quantity: 3, price: 7.99, totalTax: "3.30"), quantity: 0),
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
}
