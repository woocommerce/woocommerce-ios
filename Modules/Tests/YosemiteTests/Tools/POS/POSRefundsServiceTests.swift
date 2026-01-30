import Testing
import Foundation
@testable import Yosemite
import Networking
@testable import NetworkingCore

struct POSRefundsServiceTests {
    // MARK: - Mock PaymentGatewayRemote

    private func makeMockPOSPaymentGatewayRemote(gateways: [PaymentGateway] = []) -> MockPOSPaymentGatewayRemote {
        MockPOSPaymentGatewayRemote(gatewaysToReturn: gateways)
    }
    @Test func providePointOfSaleRefunds_then_calls_remote_with_expected_params() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let siteID: Int64 = 123
        let sut = POSRefundsService(siteID: siteID, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote())
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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote())

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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote())

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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote())

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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote(gateways: [gateway]))

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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote(gateways: [gateway]))

        let order = makeOrder(paymentMethodID: "cod")

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.supportsAutomaticRefund == false)
    }

    @Test func providePointOfSaleRefunds_when_gateway_not_found_and_payment_method_is_cod_then_supportsAutomaticRefund_is_false() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote(gateways: []))

        let order = makeOrder(paymentMethodID: "cod")

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.supportsAutomaticRefund == false)
    }

    @Test func providePointOfSaleRefunds_when_gateway_not_found_and_payment_method_is_not_cod_then_supportsAutomaticRefund_is_true() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote(gateways: []))

        let order = makeOrder(paymentMethodID: "woocommerce_payments")

        // When
        let result = try await sut.providePointOfSaleRefunds(for: order)

        // Then
        #expect(result.supportsAutomaticRefund == true)
    }

    // MARK: - createRefund Tests

    @Test func createRefund_then_calls_calculator_with_correct_parameters() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let calculator = MockPOSRefundCalculator()
        let siteID: Int64 = 123
        let sut = POSRefundsService(siteID: siteID, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote(), refundCalculator: calculator)

        let orderID: Int64 = 456
        let items = [
            POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(1), originalQuantity: 2),
            POSRefundableItem(itemID: 2, price: Decimal(20), totalTax: Decimal(2), originalQuantity: 1)
        ]
        let reason = "Customer request"

        // When
        try await sut.createRefund(orderID: orderID, items: items, reason: reason, isAutomaticRefund: true)

        // Then
        #expect(calculator.spyOrderID == orderID)
        #expect(calculator.spySelectedItems?.count == 2)
        #expect(calculator.spyReason == reason)
    }

    @Test func createRefund_then_calls_remote_with_correct_site_id_and_order_id() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let calculator = MockPOSRefundCalculator()
        let siteID: Int64 = 123
        let sut = POSRefundsService(siteID: siteID, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote(), refundCalculator: calculator)

        let orderID: Int64 = 456
        let items = [POSRefundableItem(itemID: 1, price: Decimal(10), totalTax: Decimal(1), originalQuantity: 1)]

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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote(), refundCalculator: calculator)

        // When
        try await sut.createRefund(orderID: 456, items: [], reason: "Test reason", isAutomaticRefund: true)

        // Then
        #expect(remote.spyCreateRefund?.amount == "132.60")
        #expect(remote.spyCreateRefund?.reason == "Test reason")
    }

    @Test func createRefund_when_automatic_refund_enabled_then_sets_create_automated_to_true() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: MockPOSPaymentGatewayRemote())

        // When
        try await sut.createRefund(orderID: 456, items: [], reason: nil, isAutomaticRefund: true)

        // Then
        #expect(remote.spyCreateRefund?.createAutomated == true)
    }

    @Test func createRefund_when_automatic_refund_disabled_then_sets_create_automated_to_false() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: MockPOSPaymentGatewayRemote())

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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote, paymentGatewayRemote: makeMockPOSPaymentGatewayRemote())

        // Then
        do {
            try await sut.createRefund(orderID: 456, items: [], reason: nil, isAutomaticRefund: true)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is TestError)
        }
    }

    private func makeOrder(id: Int64 = 1, paymentMethodID: String = "woocommerce_payments", refunds: [POSOrderRefund] = []) -> POSOrder {
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
            formattedNetAmount: nil
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
