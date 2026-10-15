import XCTest
import Yosemite
import WooFoundation
@testable import WooCommerce

/// Test cases for `RefundCreationUseCase`
///
final class RefundCreationUseCaseTests: XCTestCase {

    /// Default currency formatter
    ///
    private let currencySettings = CurrencySettings()
    private lazy var formatter = CurrencyFormatter(currencySettings: currencySettings)

    func test_refund_top_properties_are_correcly_translated_to_the_refund_object() {
        // Given
        let useCase = RefundCreationUseCase(amount: "10.0",
                                            reason: "Test Reason",
                                            automaticallyRefundsPayment: true,
                                            items: [],
                                            shippingLines: [],
                                            fees: [],
                                            currencyFormatter: formatter, numberOfDecimals: currencySettings.fractionDigits)

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
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 2, price: 5.1, total: "10.2", totalTax: "0.0"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 6.3, total: "12.6", totalTax: "0.0"), quantity: 2)
        ]
        let useCase = RefundCreationUseCase(amount: "17.70",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            shippingLines: [],
                                            fees: [],
                                            currencyFormatter: formatter, numberOfDecimals: currencySettings.fractionDigits)

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
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 5.1, taxes: taxes, total: "15.3", totalTax: "3.90"), quantity: 2)
        ]
        let useCase = RefundCreationUseCase(amount: "19.20",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            shippingLines: [],
                                            fees: [],
                                            currencyFormatter: formatter, numberOfDecimals: currencySettings.fractionDigits)

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
                                            shippingLines: [shippingLine],
                                            fees: [],
                                            currencyFormatter: formatter, numberOfDecimals: currencySettings.fractionDigits)

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

    func test_refund_shipping_values_with_multiple_shipping_lines_are_transformed_correctly() {
        // Given
        let firstShippingTaxes = ShippingLineTax(taxID: 2, subtotal: "", total: "0.99")
        let secondShippingTaxes = ShippingLineTax(taxID: 3, subtotal: "", total: "0.49")
        let shippingLines = [
            ShippingLine(shippingID: 5, methodTitle: "", methodID: "", total: "7.00", totalTax: "0.99", taxes: [firstShippingTaxes]),
            ShippingLine(shippingID: 6, methodTitle: "", methodID: "", total: "3.00", totalTax: "0.49", taxes: [secondShippingTaxes])
        ]
        let useCase = RefundCreationUseCase(amount: "11.48",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: [],
                                            shippingLines: shippingLines,
                                            fees: [],
                                            currencyFormatter: formatter, numberOfDecimals: currencySettings.fractionDigits)

        // When
        let refund = useCase.createRefund()

        // Then
        XCTAssertEqual(refund.items.count, 2)

        // First Shipping Line
        XCTAssertEqual(refund.items[0].itemID, 5)
        XCTAssertEqual(refund.items[0].quantity, 0)
        XCTAssertEqual(refund.items[0].total, "7.00")
        XCTAssertEqual(refund.items[0].taxes[0].taxID, 2)
        XCTAssertEqual(refund.items[0].taxes[0].total, "0.99")

        // Second Shipping Line
        XCTAssertEqual(refund.items[1].itemID, 6)
        XCTAssertEqual(refund.items[1].quantity, 0)
        XCTAssertEqual(refund.items[1].total, "3.00")
        XCTAssertEqual(refund.items[1].taxes[0].taxID, 3)
        XCTAssertEqual(refund.items[1].taxes[0].total, "0.49")
    }

    func test_refund_shipping_values_with_order_items_are_transformed_correctly() {
        // Given
        let items: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 2, price: 5.1, total: "10.2", totalTax: "0.0"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 6.3, total: "12.6", totalTax: "0.0"), quantity: 2)
        ]
        let shippingTaxes = ShippingLineTax(taxID: 2, subtotal: "", total: "0.99")
        let shippingLine = ShippingLine(shippingID: 5, methodTitle: "", methodID: "", total: "7.00", totalTax: "0.99", taxes: [shippingTaxes])
        let useCase = RefundCreationUseCase(amount: "25.69",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            shippingLines: [shippingLine],
                                            fees: [],
                                            currencyFormatter: formatter, numberOfDecimals: currencySettings.fractionDigits)

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
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 2, price: 1200.0, total: "2400", totalTax: "0.0"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 650.7, taxes: taxes, total: "1301.4", totalTax: "1130.6"), quantity: 2)
        ]
        let useCase = RefundCreationUseCase(amount: "3632",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            shippingLines: [],
                                            fees: [],
                                            currencyFormatter: formatter, numberOfDecimals: currencySettings.fractionDigits)

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
            .init(item: MockOrderItem.sampleItem(itemID: 1, quantity: 2, price: 5.1, total: "10.2", totalTax: "0.0"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 6.3, total: "12.6", totalTax: "0.0"), quantity: 2)
        ]
        let feeTaxes = OrderItemTax(taxID: 15, subtotal: "", total: "15.00")
        let expectedTransformedFeeTaxes = OrderItemTaxRefund(taxID: feeTaxes.taxID, subtotal: feeTaxes.subtotal, total: feeTaxes.total)
        let fees = [
            OrderFeeLine(feeID: 5, name: "", taxClass: "", taxStatus: .taxable, total: "45.00", totalTax: "15.00", taxes: [feeTaxes], attributes: []),
            OrderFeeLine(feeID: 6, name: "", taxClass: "", taxStatus: .taxable, total: "55.00", totalTax: "15.00", taxes: [feeTaxes], attributes: []),
            OrderFeeLine(feeID: 7, name: "", taxClass: "", taxStatus: .taxable, total: "65.00", totalTax: "15.00", taxes: [feeTaxes], attributes: [])
        ]
        let useCase = RefundCreationUseCase(amount: "227.70",
                                            reason: nil,
                                            automaticallyRefundsPayment: false,
                                            items: items,
                                            shippingLines: [],
                                            fees: fees,
                                            currencyFormatter: formatter, numberOfDecimals: currencySettings.fractionDigits)

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
    func test_create_refund_when_last_taxed_unit_remains_then_uses_saved_tax_balance() throws {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 7, quantity: 3, price: 3.33,
                                           taxes: [.init(taxID: 1, subtotal: "", total: "0.50")], total: "9.99", totalTax: "0.50")
        var selected = RefundableOrderItem(item: item, quantity: 1)
        selected.refundedItems = [8, 9].map {
            OrderItemRefund(itemID: $0, refundedItemID: "7", quantity: -1,
                            taxes: [.init(taxID: 1, subtotal: "", total: "-0.17")], total: "-3.33", totalTax: "-0.17")
        }
        // When
        let refund = RefundCreationUseCase(amount: "3.49", reason: nil, automaticallyRefundsPayment: false,
                                           items: [selected], shippingLines: [], fees: [], currencyFormatter: formatter,
                                           numberOfDecimals: currencySettings.fractionDigits).createRefund()
        // Then
        let line = try XCTUnwrap(refund.items.first)
        XCTAssertEqual(line.total, "3.33")
        XCTAssertEqual(line.taxes.first?.total, "0.16")
    }

    func test_create_refund_when_amount_is_capped_then_scales_all_net_and_tax_components() {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 7, quantity: 1, price: 100,
                                           taxes: [.init(taxID: 1, subtotal: "", total: "5")], total: "100", totalTax: "5")
        // When
        let refund = RefundCreationUseCase(amount: "50", reason: nil, automaticallyRefundsPayment: false,
                                           items: [.init(item: item, quantity: 1)], shippingLines: [], fees: [], currencyFormatter: formatter,
                                           numberOfDecimals: currencySettings.fractionDigits).createRefund()
        // Then
        XCTAssertEqual(refund.items.first?.total, "47.62")
        XCTAssertEqual(refund.items.first?.taxes.first?.total, "2.38")
    }

    func test_create_refund_when_tax_inclusive_amount_has_precision_then_gross_stays_within_line_balance() {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 7, quantity: 1,
                                           taxes: [.init(taxID: 1, subtotal: "", total: "0.115044")], total: "0.884956", totalTax: "0.12")
        // When
        let refund = RefundCreationUseCase(amount: "1", reason: nil, automaticallyRefundsPayment: false,
                                           items: [.init(item: item, quantity: 1)], shippingLines: [], fees: [], currencyFormatter: formatter,
                                           numberOfDecimals: currencySettings.fractionDigits).createRefund()
        // Then
        XCTAssertEqual(refund.items.first?.total, "0.884956")
        XCTAssertEqual(refund.items.first?.taxes.first?.total, "0.115044")
    }
    func test_create_refund_when_subtotal_tax_rounding_preserves_fractional_taxes_then_full_refund_keeps_them() {
        // Given
        let items = [1, 2].map { id in
            RefundableOrderItem(item: MockOrderItem.sampleItem(itemID: Int64(id), quantity: 1,
                                taxes: [.init(taxID: 1, subtotal: "", total: "0.004")], total: "0.10", totalTax: "0.004"), quantity: 1)
        }
        // When
        let values = RefundItemsValuesCalculationUseCase(refundItems: items, currencyFormatter: formatter,
        numberOfDecimals: currencySettings.fractionDigits).calculateRefundValues()
        let refund = RefundCreationUseCase(amount: "\(values.total)", reason: nil, automaticallyRefundsPayment: false,
                                           items: items, shippingLines: [], fees: [], currencyFormatter: formatter,
                                           numberOfDecimals: currencySettings.fractionDigits).createRefund()
        // Then
        XCTAssertEqual(RefundCreationUseCase.round(values.total, scale: 2), Decimal(string: "0.21"))
        XCTAssertEqual(refund.items.map { $0.taxes.first?.total }, ["0.004", "0.004"])
    }

    func test_create_refund_when_distributing_capped_remainder_then_each_line_stays_within_balance() {
        // Given
        let items = [1, 2, 3].map { id in
            RefundableOrderItem(item: MockOrderItem.sampleItem(itemID: Int64(id), quantity: 1,
                                taxes: [.init(taxID: 1, subtotal: "", total: "0.105")], total: "0.105", totalTax: "0.105"), quantity: 1)
        }
        // When
        let refund = RefundCreationUseCase(amount: "0.62", reason: nil, automaticallyRefundsPayment: false,
                                           items: items, shippingLines: [], fees: [], currencyFormatter: formatter,
                                           numberOfDecimals: currencySettings.fractionDigits).createRefund()
        let gross = refund.items.map { (Decimal(string: $0.total) ?? .zero) + $0.taxes.reduce(.zero) { $0 + (Decimal(string: $1.total) ?? .zero) } }
        // Then
        XCTAssertEqual(gross.reduce(.zero, +), Decimal(string: "0.62"))
        XCTAssertTrue(gross.allSatisfy { $0 <= Decimal(21) / 100 })
    }

    func test_create_refund_when_capped_at_store_precision_then_net_and_tax_fit_requested_amount() {
        for scale in [0, 2, 3] {
            // Given
            let item = MockOrderItem.sampleItem(itemID: 1, quantity: 1,
                                               taxes: [.init(taxID: 1, subtotal: "", total: "5")], total: "100", totalTax: "5")
            // When
            let refund = RefundCreationUseCase(amount: "50", reason: nil, automaticallyRefundsPayment: false,
                                               items: [.init(item: item, quantity: 1)], shippingLines: [], fees: [],
                                               currencyFormatter: formatter, numberOfDecimals: scale).createRefund()
            let line = refund.items[0]
            let gross = (Decimal(string: line.total) ?? .zero) + line.taxes.reduce(.zero) { $0 + (Decimal(string: $1.total) ?? .zero) }
            // Then
            XCTAssertEqual(gross, 50)
            XCTAssertEqual(RefundCreationUseCase.round(gross, scale: scale), gross)
        }
    }

    func test_create_refund_when_capped_selection_contains_free_product_then_preserves_its_quantity() {
        // Given
        let paid = MockOrderItem.sampleItem(itemID: 1, quantity: 1, total: "100")
        let free = MockOrderItem.sampleItem(itemID: 2, quantity: 1, total: "0")
        // When
        let refund = RefundCreationUseCase(amount: "50", reason: nil, automaticallyRefundsPayment: false,
                                           items: [.init(item: paid, quantity: 1), .init(item: free, quantity: 1)],
                                           shippingLines: [], fees: [], currencyFormatter: formatter,
                                           numberOfDecimals: currencySettings.fractionDigits).createRefund()
        // Then
        XCTAssertEqual(refund.items.map(\.itemID), [1, 2])
        XCTAssertEqual(refund.items.map(\.quantity), [1, 1])
        XCTAssertEqual(refund.items.map(\.total), ["50", "0"])
    }

    func test_create_refund_when_negative_fees_have_fractional_precision_then_cap_keeps_their_balances() {
        for (total, count, amount, expectedNet) in [("-1.001", 1, "98.99", "99.99"), ("-1.004", 3, "96.98", "99.98")] {
            // Given
            let item = MockOrderItem.sampleItem(itemID: 1, quantity: 1, total: "100")
            let fees = (0..<count).map { OrderFeeLine.fake().copy(feeID: Int64($0 + 2), total: total, totalTax: "0", taxes: []) }
            // When
            let refund = RefundCreationUseCase(amount: amount, reason: nil, automaticallyRefundsPayment: false,
                                               items: [.init(item: item, quantity: 1)], shippingLines: [], fees: fees,
                                               currencyFormatter: formatter, numberOfDecimals: currencySettings.fractionDigits).createRefund()
            // Then
            XCTAssertEqual(refund.items.map(\.total), [expectedNet] + Array(repeating: "-1", count: count))
            XCTAssertEqual(refund.items.reduce(Decimal.zero) { $0 + (Decimal(string: $1.total) ?? .zero) }, Decimal(string: amount))
        }
    }
}
