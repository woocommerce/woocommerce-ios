import Testing
import Foundation
@testable import Yosemite
import Networking
@testable import NetworkingCore
import class WooFoundation.CurrencySettings

struct POSRefundsServiceTests {
    private let currencySettings = CurrencySettings()

    // MARK: - Helpers

    private func makeSUT(
        siteID: Int64 = 123,
        remote: MockPOSRefundsRemote = MockPOSRefundsRemote(),
        gateways: [PaymentGateway] = [],
        calculator: POSRefundCalculating? = nil
    ) -> POSRefundsService {
        POSRefundsService(
            siteID: siteID,
            refundsRemote: remote,
            paymentGatewayRemote: MockPOSPaymentGatewayRemote(gatewaysToReturn: gateways),
            currencySettings: currencySettings,
            refundCalculator: calculator ?? POSRefundCalculator()
        )
    }

    @Test func providePointOfSaleRefunds_then_calls_remote_with_expected_params() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let siteID: Int64 = 123
        let sut = makeSUT(siteID: siteID, remote: remote)
        let orderRefunds = [POSOrderRefund(refundID: 10, formattedTotal: "$22"), POSOrderRefund(refundID: 20, formattedTotal: "$22")]

        let order = makeOrder(id: 1, refunds: orderRefunds)

        // When
        _ = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(remote.spySiteID == siteID)
        #expect(remote.spyOrderID == order.id)
        #expect(remote.spyRefundIDs == orderRefunds.map { $0.refundID })
    }

    @Test func providePointOfSaleRefunds_when_remote_fails_then_propagates_remote_error() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        struct TestError: Error {}
        remote.result = .failure(TestError())

        let order = makeOrder()


        // Then
        do {
            _ = try await sut.providePointOfSaleRefunds(for: order)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is TestError)
        }
    }

    @Test func providePointOfSaleRefunds_when_remote_succeeds_then_returns_same_count_as_remote() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        let r1 = MockRefunds.sampleRefund()
        let r2 = MockRefunds.sampleRefund()
        remote.result = .success([r1, r2])

        let order = makeOrder()


        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.refunds.count == 2)
    }

    @Test func providePointOfSaleRefunds_when_remote_succeeds_then_maps_refund_items_correctly() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        let item1 = MockRefunds.sampleRefundItem(productID: 111, variationID: 222, quantity: 2)
        let item2 = MockRefunds.sampleRefundItem(productID: 333, variationID: 444, quantity: 5)

        let refund = MockRefunds.sampleRefund(items: [item1, item2])
        remote.result = .success([refund])

        let order = makeOrder()

        // When
        let posRefunds = try await sut.providePointOfSaleRefunds(for: order).refunds

        // Then
        #expect(posRefunds.count == 1)
        #expect(posRefunds[0].items.count == 2)

        let mappedItems = posRefunds[0].items

        #expect(mappedItems[0].quantity == item1.quantity)
        #expect(mappedItems[1].quantity == item2.quantity)
    }

    // MARK: - supportsAutomaticRefund Tests

    @Test func providePointOfSaleRefunds_when_gateway_supports_refunds_then_supportsAutomaticRefund_is_true() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let gateway = PaymentGateway(siteID: 123,
                                     gatewayID: "woocommerce_payments",
                                     title: "WooCommerce Payments",
                                     description: "",
                                     enabled: true,
                                     features: [.refunds],
                                     instructions: nil)
        let sut = makeSUT(remote: remote, gateways: [gateway])

        let order = makeOrder(paymentMethodID: "woocommerce_payments")

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.supportsAutomaticRefund == true)
    }

    @Test func providePointOfSaleRefunds_when_gateway_does_not_support_refunds_then_supportsAutomaticRefund_is_false() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let gateway = PaymentGateway(siteID: 123,
                                     gatewayID: "cod",
                                     title: "Cash on Delivery",
                                     description: "",
                                     enabled: true,
                                     features: [],
                                     instructions: nil)
        let sut = makeSUT(remote: remote, gateways: [gateway])

        let order = makeOrder(paymentMethodID: "cod")

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.supportsAutomaticRefund == false)
    }

    @Test func providePointOfSaleRefunds_when_gateway_not_found_and_payment_method_is_cod_then_supportsAutomaticRefund_is_false() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        let order = makeOrder(paymentMethodID: "cod")

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.supportsAutomaticRefund == false)
    }

    @Test func providePointOfSaleRefunds_when_gateway_not_found_and_payment_method_is_not_cod_then_supportsAutomaticRefund_is_true() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        let order = makeOrder(paymentMethodID: "woocommerce_payments")

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.supportsAutomaticRefund == true)
    }

    // MARK: - isFullyRefunded Tests

    @Test func providePointOfSaleRefunds_when_all_items_refunded_with_negative_quantities_then_isFullyRefunded_is_true() async throws {
        // Given: Order has 2 units of product 111
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        // API returns negative quantities for refunds (-2 means 2 items refunded)
        let refundItem = MockRefunds.sampleRefundItem(productID: 111, variationID: 0, quantity: -2)
        let refund = MockRefunds.sampleRefund(items: [refundItem])
        remote.result = .success([refund])

        let order = makeOrder(lineItemQuantitiesByProductOrVariationID: [111: 2])

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.isFullyRefunded == true)
    }

    @Test func providePointOfSaleRefunds_when_partial_items_refunded_then_isFullyRefunded_is_false() async throws {
        // Given: Order has 3 units of product 111
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        // Only 2 items refunded (negative quantity from API)
        let refundItem = MockRefunds.sampleRefundItem(productID: 111, variationID: 0, quantity: -2)
        let refund = MockRefunds.sampleRefund(items: [refundItem])
        remote.result = .success([refund])

        let order = makeOrder(lineItemQuantitiesByProductOrVariationID: [111: 3])

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.isFullyRefunded == false)
    }

    @Test func providePointOfSaleRefunds_when_variation_fully_refunded_then_isFullyRefunded_is_true() async throws {
        // Given: Order has 1 unit of variation 222 (of product 111)
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        // Variation refunded (negative quantity from API)
        let refundItem = MockRefunds.sampleRefundItem(productID: 111, variationID: 222, quantity: -1)
        let refund = MockRefunds.sampleRefund(items: [refundItem])
        remote.result = .success([refund])

        // Key is variationID when variation exists
        let order = makeOrder(lineItemQuantitiesByProductOrVariationID: [222: 1])

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.isFullyRefunded == true)
    }

    // MARK: - loadRefundData Tests

    @Test func loadRefundData_then_calls_remote_with_expected_params() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let siteID: Int64 = 123
        let sut = makeSUT(siteID: siteID, remote: remote)
        let orderRefunds = [
            POSOrderRefund(refundID: 10, formattedTotal: "-$22"),
            POSOrderRefund(refundID: 20, formattedTotal: "-$15")
        ]
        let order = makeOrder(id: 1, refunds: orderRefunds)

        // When
        _ = try await sut.loadOrderRefunds(for: order)

        // Then
        #expect(remote.spySiteID == siteID)
        #expect(remote.spyOrderID == order.id)
        #expect(remote.spyRefundIDs == [10, 20])
    }

    @Test func loadRefundData_when_remote_fails_then_propagates_error() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        struct TestError: Error {}
        remote.result = .failure(TestError())
        let sut = makeSUT(remote: remote)
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10")])

        // Then
        do {
            _ = try await sut.loadOrderRefunds(for: order)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is TestError)
        }
    }

    @Test func loadRefundData_then_maps_refunds_with_dateCreated() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)
        let expectedDate = Date(timeIntervalSince1970: 1000000)
        let refund = MockRefunds.sampleRefund(refundID: 10, dateCreated: expectedDate, amount: "25.50", reason: "Customer request")
        remote.result = .success([refund])
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 10, formattedTotal: "-$25.50")])

        // When
        let result = try await sut.loadOrderRefunds(for: order)

        // Then
        #expect(result.count == 1)
        #expect(result[0].refundID == 10)
        #expect(result[0].dateCreated == expectedDate)
        #expect(result[0].reason == "Customer request")
    }

    @Test func loadRefundData_then_formats_enrichedRefund_amount_as_negative() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)
        let refund = MockRefunds.sampleRefund(refundID: 1, amount: "42.99")
        remote.result = .success([refund])
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$42.99")])

        // When
        let result = try await sut.loadOrderRefunds(for: order)

        // Then
        #expect(result[0].formattedTotal.contains("-"))
        #expect(result[0].formattedTotal.contains("42.99"))
    }

    @Test func loadRefundData_when_reason_is_empty_then_enrichedRefund_reason_is_nil() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)
        let refund = MockRefunds.sampleRefund(refundID: 1, reason: "")
        remote.result = .success([refund])
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10")])

        // When
        let result = try await sut.loadOrderRefunds(for: order)

        // Then
        #expect(result[0].reason == nil)
    }

    @Test func loadOrderRefunds_then_refunds_contain_items_and_subtotal_and_tax() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)
        let items = [
            MockRefunds.sampleRefundItem(name: "Cup", quantity: -1, price: 18.00, total: "-18.00", totalTax: "-3.60"),
            MockRefunds.sampleRefundItem(itemID: 2, name: "Mug", refundedItemID: "2", quantity: -2, price: 5.00, total: "-10.00", totalTax: "-2.00")
        ]
        let refund = MockRefunds.sampleRefund(refundID: 1, amount: "33.60", items: items)
        remote.result = .success([refund])
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$33.60")])

        // When
        let result = try await sut.loadOrderRefunds(for: order)

        // Then
        #expect(result[0].items.count == 2)
        #expect(result[0].itemCount == 2)
        #expect(result[0].formattedItemsSubtotal.contains("28.00"))
        #expect(result[0].formattedTax.contains("5.60"))
    }

    // MARK: - createRefund Tests

    @Test func createRefund_then_calls_calculator_with_correct_parameters() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let calculator = MockPOSRefundCalculator()
        let siteID: Int64 = 123
        let sut = makeSUT(siteID: siteID, remote: remote, calculator: calculator)

        let orderID: Int64 = 456
        let items = [
            POSRefundableItem(itemID: 1, lineItemTotal: Decimal(20), totalTax: Decimal(2), originalQuantity: 2),
            POSRefundableItem(itemID: 2, lineItemTotal: Decimal(20), totalTax: Decimal(2), originalQuantity: 1)
        ]
        let reason = "Customer request"

        // When
        try await sut.createRefund(orderID: orderID, items: items, reason: reason, isAutomaticRefund: true)

        // Then
        #expect(calculator.spyOrderID == orderID)
        #expect(calculator.spySelectedItems?.count == 2)
        #expect(calculator.spyReason == reason)
    }

    @Test func createRefund_then_passes_fraction_digits_from_currency_settings_to_calculator() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let calculator = MockPOSRefundCalculator()
        let currencySettings = CurrencySettings(
            currencyCode: .JPY,
            currencyPosition: .left,
            thousandSeparator: ",",
            decimalSeparator: ".",
            numberOfDecimals: 0
        )
        let sut = POSRefundsService(
            siteID: 123,
            refundsRemote: remote,
            paymentGatewayRemote: MockPOSPaymentGatewayRemote(),
            currencySettings: currencySettings,
            refundCalculator: calculator
        )

        // When
        try await sut.createRefund(orderID: 456, items: [], reason: nil, isAutomaticRefund: true)

        // Then
        #expect(calculator.spyNumberOfDecimals == 0)
    }

    @Test func createRefund_when_three_decimal_currency_then_formats_amount_with_three_decimals() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let calculator = MockPOSRefundCalculator()
        calculator.stubRefundRequest = POSRefundRequest(
            orderID: 456,
            amount: Decimal(string: "100.123")!,
            reason: nil,
            items: []
        )
        let currencySettings = CurrencySettings(
            currencyCode: .KWD,
            currencyPosition: .left,
            thousandSeparator: ",",
            decimalSeparator: ".",
            numberOfDecimals: 3
        )
        let sut = POSRefundsService(
            siteID: 123,
            refundsRemote: remote,
            paymentGatewayRemote: MockPOSPaymentGatewayRemote(),
            currencySettings: currencySettings,
            refundCalculator: calculator
        )

        // When
        try await sut.createRefund(orderID: 456, items: [], reason: nil, isAutomaticRefund: true)

        // Then
        #expect(remote.spyCreateRefund?.amount == "100.123")
    }

    @Test func createRefund_then_calls_remote_with_correct_site_id_and_order_id() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let calculator = MockPOSRefundCalculator()
        let siteID: Int64 = 123
        let sut = makeSUT(siteID: siteID, remote: remote, calculator: calculator)

        let orderID: Int64 = 456
        let items = [POSRefundableItem(itemID: 1, lineItemTotal: Decimal(10), totalTax: Decimal(1), originalQuantity: 1)]

        // When
        try await sut.createRefund(orderID: orderID, items: items, reason: nil, isAutomaticRefund: true)

        // Then
        #expect(remote.spyCreateRefundSiteID == siteID)
        #expect(remote.spyCreateRefundOrderID == orderID)
    }

    @Test func createRefund_then_builds_refund_with_correct_amount_from_calculator() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let calculator = MockPOSRefundCalculator()
        calculator.stubRefundRequest = POSRefundRequest(
            orderID: 456,
            amount: Decimal(string: "132.60")!,
            reason: "Test reason",
            items: []
        )
        let sut = makeSUT(remote: remote, calculator: calculator)

        // When
        try await sut.createRefund(orderID: 456, items: [], reason: "Test reason", isAutomaticRefund: true)

        // Then
        #expect(remote.spyCreateRefund?.amount == "132.60")
        #expect(remote.spyCreateRefund?.reason == "Test reason")
    }

    @Test func createRefund_when_automatic_refund_enabled_then_sets_create_automated_to_true() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        // When
        try await sut.createRefund(orderID: 456, items: [], reason: nil, isAutomaticRefund: true)

        // Then
        #expect(remote.spyCreateRefund?.createAutomated == true)
    }

    @Test func createRefund_when_automatic_refund_disabled_then_sets_create_automated_to_false() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = makeSUT(remote: remote)

        // When
        try await sut.createRefund(orderID: 456, items: [], reason: nil, isAutomaticRefund: false)

        // Then
        #expect(remote.spyCreateRefund?.createAutomated == false)
    }

    @Test func createRefund_when_remote_fails_then_propagates_error() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        struct TestError: Error {}
        remote.createRefundResult = .failure(TestError())
        let sut = makeSUT(remote: remote)

        // Then
        do {
            try await sut.createRefund(orderID: 456, items: [], reason: nil, isAutomaticRefund: true)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is TestError)
        }
    }

    private func makeOrder(
        id: Int64 = 1,
        paymentMethodID: String = "woocommerce_payments",
        refunds: [POSOrderRefund] = [],
        lineItemQuantitiesByProductOrVariationID: [Int64: Decimal] = [:]
    ) -> POSOrder {
        POSOrder(
            id: id,
            number: "1001",
            dateCreated: Date(),
            status: .completed,
            formattedTotal: "$10.00",
            formattedSubtotal: "$10.00",
            customerEmail: "test1@example.com",
            paymentMethodID: paymentMethodID,
            paymentMethodTitle: "Credit Card",
            lineItems: [],
            refunds: refunds,
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$10.00",
            formattedNetAmount: nil,
            datePaid: Date(),
            lineItemQuantitiesByProductOrVariationID: lineItemQuantitiesByProductOrVariationID
        )
    }
}

public struct MockRefunds {
    public static func sampleRefund(refundID: Int64 = 0,
                                    orderID: Int64 = 0,
                                    siteID: Int64 = 0,
                                    dateCreated: Date = Date(),
                                    amount: String = "0.0",
                                    reason: String = "",
                                    refundedByUserID: Int64 = 0,
                                    isAutomated: Bool? = nil,
                                    createAutomated: Bool? = nil,
                                    items: [OrderItemRefund] = [sampleRefundItem()],
                                    shippingLines: [ShippingLine]? = []) -> Refund {
        return Refund(refundID: refundID,
                      orderID: orderID,
                      siteID: siteID,
                      dateCreated: dateCreated,
                      amount: amount,
                      reason: reason,
                      refundedByUserID: refundedByUserID,
                      isAutomated: isAutomated,
                      createAutomated: createAutomated,
                      items: items,
                      shippingLines: shippingLines)
    }

    public static func sampleRefundItem(itemID: Int64 = 0,
                                        name: String = "",
                                        productID: Int64 = 0,
                                        variationID: Int64 = 0,
                                        refundedItemID: String = "1",
                                        quantity: Decimal = 0,
                                        price: NSDecimalNumber = 0,
                                        sku: String? = nil,
                                        subtotal: String = "0.0",
                                        subtotalTax: String = "0.0",
                                        taxClass: String = "",
                                        taxes: [OrderItemTaxRefund] = [],
                                        total: String = "0.0",
                                        totalTax: String = "0.0") -> OrderItemRefund {
        return OrderItemRefund(itemID: itemID,
                               name: name,
                               productID: productID,
                               variationID: variationID,
                               refundedItemID: refundedItemID,
                               quantity: quantity,
                               price: price,
                               sku: sku,
                               subtotal: subtotal,
                               subtotalTax: subtotalTax,
                               taxClass: taxClass,
                               taxes: taxes,
                               total: total,
                               totalTax: totalTax)
    }

    public static func sampleShippingLine() -> ShippingLine {
        ShippingLine(shippingID: 0,
                     methodTitle: "",
                     methodID: "",
                     total: "",
                     totalTax: "",
                     taxes: [ShippingLineTax(taxID: 0, subtotal: "", total: "")])
    }
}

// MARK: - MockPOSPaymentGatewayRemote

final class MockPOSPaymentGatewayRemote: POSPaymentGatewayRemoteProtocol {
    var gatewaysToReturn: [PaymentGateway] = []

    init(gatewaysToReturn: [PaymentGateway] = []) {
        self.gatewaysToReturn = gatewaysToReturn
    }

    func loadAllPaymentGateways(siteID: Int64, completion: @escaping (Result<[PaymentGateway], Error>) -> Void) {
        completion(.success(gatewaysToReturn))
    }
}
