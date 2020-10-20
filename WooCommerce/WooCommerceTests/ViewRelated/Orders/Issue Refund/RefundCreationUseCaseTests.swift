import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `RefundCreationUseCase`
///
final class RefundCreationUseCaseTests: XCTestCase {

    /// Default currency formatter
    ///
    private let formatter = CurrencyFormatter(currencySettings: CurrencySettings())

    func test_refund_top_properties_are_correcly_translated_to_the_refund_object() {
        // Given
        let useCase = RefundCreationUseCase(amount: "10.0",
                                            reason: "Test Reason",
                                            automaticallyRefundsPayment: true,
                                            items: [],
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefundObject()

        // Then
        XCTAssertEqual(refund.amount, "10.0")
        XCTAssertEqual(refund.reason, "Test Reason")
        XCTAssertEqual(refund.createAutomated, true)
    }

    func test_refund_order_items_values_are_transformed_with_no_taxes() {
        // Given
        let items: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 2, price: 5.1, totalTax: "0.0"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 6.3, totalTax: "0.0"), quantity: 2)
        ]
        let useCase = RefundCreationUseCase(amount: "17.60",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefundObject()

        // Then
        XCTAssertEqual(refund.items.count, items.count)
        XCTAssertEqual(refund.items[0].itemID, 1)
        XCTAssertEqual(refund.items[1].itemID, 2)

        XCTAssertEqual(refund.items[0].quantity, 1)
        XCTAssertEqual(refund.items[1].quantity, 2)

        XCTAssertEqual(refund.items[0].total, "5.10")
        XCTAssertEqual(refund.items[1].total, "12.60")

        XCTAssertEqual(refund.items[0].totalTax, "0.00")
        XCTAssertEqual(refund.items[1].totalTax, "0.00")

        XCTAssertEqual(refund.items[0].taxes, [])
        XCTAssertEqual(refund.items[0].taxes, [])
    }

    func test_refund_order_items_values_are_transformed_with_taxes() {
        // Given
        let taxes = [
            OrderItemTax(taxID: 11, subtotal: "", total: "0.60"),
            OrderItemTax(taxID: 12, subtotal: "", total: "3.30")
        ]
        let items: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 5.1, taxes: taxes, totalTax: "3.90"), quantity: 2)
        ]
        let useCase = RefundCreationUseCase(amount: "19.20",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefundObject()

        // Then
        XCTAssertEqual(refund.items.count, items.count)
        XCTAssertEqual(refund.items[0].itemID, 1)
        XCTAssertEqual(refund.items[0].quantity, 2)
        XCTAssertEqual(refund.items[0].total, "10.20")
        XCTAssertEqual(refund.items[0].totalTax, "2.60")
        XCTAssertEqual(refund.items[0].taxes[0].taxID, 11)
        XCTAssertEqual(refund.items[0].taxes[0].total, "0.40")
        XCTAssertEqual(refund.items[0].taxes[1].taxID, 12)
        XCTAssertEqual(refund.items[0].taxes[1].total, "2.20")
    }
}
