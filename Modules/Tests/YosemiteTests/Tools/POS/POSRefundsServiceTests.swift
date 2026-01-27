import Testing
import Foundation
@testable import Yosemite
import Networking

struct POSRefundsServiceTests {
    @Test func providePointOfSaleRefunds_then_calls_remote_with_expected_params() async throws {
        // Given
        let remote = MockPOSRefundsRemote()
        let siteID: Int64 = 123
        let sut = POSRefundsService(siteID: siteID, refundsRemote: remote)
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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote)

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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote)

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
        let sut = POSRefundsService(siteID: 123, refundsRemote: remote)

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

    private func makeOrder(id: Int64 = 1, refunds: [POSOrderRefund] = []) -> POSOrder {
        POSOrder(
            id: id,
            number: "1001",
            dateCreated: Date(),
            status: .completed,
            formattedTotal: "$10.00",
            formattedSubtotal: "$10.00",
            customerEmail: "test1@example.com",
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
