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
                                            shippingLine: nil,
                                            fees: [],
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefund()

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
                                            shippingLine: nil,
                                            fees: [],
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefund()

        // Then
        XCTAssertEqual(refund.items.count, items.count)
        XCTAssertEqual(refund.items[0].itemID, 1)
        XCTAssertEqual(refund.items[1].itemID, 2)

        XCTAssertEqual(refund.items[0].quantity, 1)
        XCTAssertEqual(refund.items[1].quantity, 2)

        XCTAssertEqual(refund.items[0].total, "5.1")
        XCTAssertEqual(refund.items[1].total, "12.6")

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
                                            shippingLine: nil,
                                            fees: [],
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefund()

        // Then
        XCTAssertEqual(refund.items.count, items.count)
        XCTAssertEqual(refund.items[0].itemID, 1)
        XCTAssertEqual(refund.items[0].quantity, 2)
        XCTAssertEqual(refund.items[0].total, "10.2")
        XCTAssertEqual(refund.items[0].taxes[0].taxID, 11)
        XCTAssertEqual(refund.items[0].taxes[0].total, "0.4")
        XCTAssertEqual(refund.items[0].taxes[1].taxID, 12)
        XCTAssertEqual(refund.items[0].taxes[1].total, "2.2")
    }

    func test_refund_shipping_values_with_no_items_are_transformed_correctly() {
        // Given
        let shippingTaxes = ShippingLineTax(taxID: 2, subtotal: "", total: "0.99")
        let shippingLine = ShippingLine(shippingID: 5, methodTitle: "", methodID: "", total: "7.00", totalTax: "0.99", taxes: [shippingTaxes])
        let useCase = RefundCreationUseCase(amount: "7.99",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: [],
                                            shippingLine: shippingLine,
                                            fees: [],
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefund()

        // Then
        XCTAssertEqual(refund.items.count, 1)

        // Shipping Line
        XCTAssertEqual(refund.items[0].itemID, 5)
        XCTAssertEqual(refund.items[0].quantity, 0)
        XCTAssertEqual(refund.items[0].total, "7.00")

        // Shipping Line taxes
        XCTAssertEqual(refund.items[0].taxes[0].taxID, 2)
        XCTAssertEqual(refund.items[0].taxes[0].total, "0.99")
    }

    func test_refund_shipping_values_with_order_items_are_transformed_correctly() {
        // Given
        let items: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 2, price: 5.1, totalTax: "0.0"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 6.3, totalTax: "0.0"), quantity: 2)
        ]
        let shippingTaxes = ShippingLineTax(taxID: 2, subtotal: "", total: "0.99")
        let shippingLine = ShippingLine(shippingID: 5, methodTitle: "", methodID: "", total: "7.00", totalTax: "0.99", taxes: [shippingTaxes])
        let useCase = RefundCreationUseCase(amount: "7.99",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            shippingLine: shippingLine,
                                            fees: [],
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefund()

        // Then
        XCTAssertEqual(refund.items.count, items.count + 1) // 1 from the shipping line

        // Fist Item
        XCTAssertEqual(refund.items[0].itemID, 1)
        XCTAssertEqual(refund.items[0].quantity, 1)
        XCTAssertEqual(refund.items[0].total, "5.1")
        XCTAssertEqual(refund.items[0].taxes, [])

        // Second Item
        XCTAssertEqual(refund.items[1].itemID, 2)
        XCTAssertEqual(refund.items[1].quantity, 2)
        XCTAssertEqual(refund.items[1].total, "12.6")
        XCTAssertEqual(refund.items[0].taxes, [])

        // Shipping Line
        XCTAssertEqual(refund.items[2].itemID, 5)
        XCTAssertEqual(refund.items[2].quantity, 0)
        XCTAssertEqual(refund.items[2].total, "7.00")
        XCTAssertEqual(refund.items[2].taxes[0].taxID, 2)
        XCTAssertEqual(refund.items[2].taxes[0].total, "0.99")
    }

    func test_refund_shipping_values_does_not_contain_thousands_separator_when_computing_big_amounts() {
        // Given
        let taxes = [
            OrderItemTax(taxID: 11, subtotal: "", total: "1130.6"),
        ]
        let items: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 2, price: 1200.0, totalTax: "0.0"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 650.7, taxes: taxes, totalTax: "1130.6"), quantity: 2)
        ]
        let useCase = RefundCreationUseCase(amount: "17.60",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            shippingLine: nil,
                                            fees: [],
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefund()

        // Then
        XCTAssertEqual(refund.items[0].total, "1200")
        XCTAssertEqual(refund.items[1].total, "1301.4")
        XCTAssertEqual(refund.items[1].taxes[0].total, "1130.6")
    }

    func test_refund_fees_values_are_transformed_correctly() {
        // Given
        let items: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 2, price: 5.1, totalTax: "0.0"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 6.3, totalTax: "0.0"), quantity: 2)
        ]
        let feeTaxes = OrderItemTax(taxID: 15, subtotal: "", total: "15.00")
        let expectedTransformedFeeTaxes = OrderItemTaxRefund(taxID: feeTaxes.taxID, subtotal: feeTaxes.subtotal, total: feeTaxes.total)
        let fees = [
            OrderFeeLine(feeID: 5, name: "", taxClass: "", taxStatus: .taxable, total: "45.00", totalTax: "15.00", taxes: [feeTaxes], attributes: []),
            OrderFeeLine(feeID: 6, name: "", taxClass: "", taxStatus: .taxable, total: "55.00", totalTax: "15.00", taxes: [feeTaxes], attributes: []),
            OrderFeeLine(feeID: 7, name: "", taxClass: "", taxStatus: .taxable, total: "65.00", totalTax: "15.00", taxes: [feeTaxes], attributes: [])
        ]
        let useCase = RefundCreationUseCase(amount: "7.99",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            shippingLine: nil,
                                            fees: fees,
                                            currencyFormatter: formatter)

        // When
        let refund = useCase.createRefund()

        // Then
        XCTAssertEqual(refund.items.count, items.count + 3) // 3 from the fees

        // First Item
        XCTAssertEqual(refund.items[0].itemID, 1)
        XCTAssertEqual(refund.items[0].quantity, 1)
        XCTAssertEqual(refund.items[0].total, "5.1")
        XCTAssertEqual(refund.items[0].taxes, [])

        // Second Item
        XCTAssertEqual(refund.items[1].itemID, 2)
        XCTAssertEqual(refund.items[1].quantity, 2)
        XCTAssertEqual(refund.items[1].total, "12.6")
        XCTAssertEqual(refund.items[1].taxes, [])

        // First Fee
        XCTAssertEqual(refund.items[2].itemID, 5)
        XCTAssertEqual(refund.items[2].total, "45.00")
        XCTAssertEqual(refund.items[2].taxes, [expectedTransformedFeeTaxes])

        // Second Fee
        XCTAssertEqual(refund.items[3].itemID, 6)
        XCTAssertEqual(refund.items[3].total, "55.00")
        XCTAssertEqual(refund.items[3].taxes, [expectedTransformedFeeTaxes])

        // Third Fee
        XCTAssertEqual(refund.items[4].itemID, 7)
        XCTAssertEqual(refund.items[4].total, "65.00")
        XCTAssertEqual(refund.items[4].taxes, [expectedTransformedFeeTaxes])

    }
}
