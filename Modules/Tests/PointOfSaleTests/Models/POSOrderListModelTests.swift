import Testing
import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder
import enum NetworkingCore.OrderStatusEnum

final class POSOrderListModelTests {
    private let mockOrdersController = MockPOSOrderListController()
    private let mockReceiptSender = MockPOSReceiptSender()
    private lazy var sut = POSOrderListModel(
        ordersController: mockOrdersController,
        receiptSender: mockReceiptSender
    )

    @Test func sendReceipt_when_successful_then_calls_receipt_controller_and_updates_order() async throws {
        // Given
        let testOrder = makeTestOrder(id: 123, email: "original@example.com")
        let testEmail = "updated@example.com"

        // When
        try await sut.sendReceipt(order: testOrder, email: testEmail)

        // Then
        #expect(mockReceiptSender.sendReceiptWasCalled == true)
        #expect(mockReceiptSender.sendReceiptCalledWithOrderID == 123)
        #expect(mockReceiptSender.sendReceiptCalledWithEmail == testEmail)
        #expect(mockOrdersController.updateOrderCalled == true)
        #expect(mockOrdersController.spyUpdateOrderID == 123)
    }

    @Test func sendReceipt_when_receipt_fails_then_throws_error_and_does_not_update_order() async throws {
        // Given
        let testOrder = makeTestOrder(id: 789, email: "fail@example.com")
        let testEmail = "error@example.com"
        mockReceiptSender.sendReceiptErrorToThrow = MockPOSReceiptSender.TestError.sendReceiptFailed

        // When & Then
        await #expect(throws: MockPOSReceiptSender.TestError.sendReceiptFailed) {
            try await sut.sendReceipt(order: testOrder, email: testEmail)
        }

        // Receipt controller should have been called
        #expect(mockReceiptSender.sendReceiptWasCalled == true)

        // But order update should NOT have been called since receipt failed
        #expect(mockOrdersController.updateOrderCalled == false)
    }

    @Test func sendReceipt_when_updateOrder_fails_then_throws_error() async throws {
        // Given
        let testOrder = makeTestOrder(id: 999, email: "update-fail@example.com")
        let testEmail = "success@example.com"
        mockOrdersController.shouldThrowError = true

        // When & Then
        await #expect(throws: MockPOSOrderListController.TestError.updateOrderFailed) {
            try await sut.sendReceipt(order: testOrder, email: testEmail)
        }

        // Receipt should have succeeded before update failed
        #expect(mockReceiptSender.sendReceiptWasCalled == true)
        #expect(mockReceiptSender.sendReceiptCalledWithOrderID == 999)
        #expect(mockReceiptSender.sendReceiptCalledWithEmail == testEmail)
        #expect(mockOrdersController.updateOrderCalled == true)
        #expect(mockOrdersController.spyUpdateOrderID == 999)
    }

    private func makeTestOrder(id: Int64, email: String) -> POSOrder {
        POSOrder(
            id: id,
            number: "\(id)",
            dateCreated: Date(),
            status: .completed,
            formattedTotal: "$10.00",
            formattedSubtotal: "$10.00",
            customerEmail: email,
            paymentMethodID: "woocommerce_payments",
            paymentMethodTitle: "Test Payment",
            lineItems: [],
            refunds: [],
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$10.00",
            formattedNetAmount: nil
        )
    }
}
