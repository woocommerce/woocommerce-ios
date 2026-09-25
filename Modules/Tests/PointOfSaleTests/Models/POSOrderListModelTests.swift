import Testing
import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderRefund
import enum NetworkingCore.OrderStatusEnum

@MainActor
@Suite(.timeLimit(.minutes(5)))
final class POSOrderListModelTests {
    private let mockOrdersController = MockPOSOrderListController()
    private let mockRefundController = MockPOSRefundController()
    private let mockReceiptSender = MockPOSReceiptSender()
    private lazy var sut = POSOrderListModel(
        ordersController: mockOrdersController,
        refundController: mockRefundController,
        receiptSender: mockReceiptSender,
        refundSubmissionModel: POSRefundSubmissionModel()
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

    @Test func selectOrder_then_selects_the_order_and_resets_the_refund_flow() async throws {
        // Given
        let testOrder = makeTestOrder(id: 321, email: "customer@example.com")

        // When
        sut.selectOrder(testOrder)

        // Then
        #expect(mockOrdersController.selectedOrder?.id == 321)
        #expect(mockRefundController.resetCalled == true)
    }

    @Test func startRefundFlow_then_starts_it_for_the_selected_order() async throws {
        // Given
        mockOrdersController.selectedOrder = makeTestOrder(id: 555, email: "customer@example.com")

        // When
        let result = await sut.startRefundFlow()

        // Then
        #expect(mockRefundController.startRefundFlowOrderID == 555)
        #expect(result == .hasItemsToRefund)
    }

    @Test func startRefundFlow_when_no_order_is_selected_then_fails_without_starting_it() async throws {
        // When
        let result = await sut.startRefundFlow()

        // Then
        #expect(mockRefundController.startRefundFlowOrderID == nil)
        #expect(result == .failed)
    }

    @Test func preloadRefund_then_preloads_for_the_selected_order() async throws {
        // Given
        mockOrdersController.selectedOrder = makeTestOrder(id: 777, email: "customer@example.com")

        // When
        await sut.preloadRefund()

        // Then
        #expect(mockRefundController.preloadedOrderID == 777)
    }

    @Test func preloadRefund_when_no_order_is_selected_then_does_not_preload() async throws {
        // When
        await sut.preloadRefund()

        // Then
        #expect(mockRefundController.preloadedOrderID == nil)
    }

    @Test func processRefund_when_successful_then_refreshes_the_refunded_order() async throws {
        // Given
        mockRefundController.stubRefundedOrderID = 456

        // When
        try await sut.processRefund(reason: "Damaged")

        // Then
        #expect(mockRefundController.processRefundCalled == true)
        #expect(mockRefundController.spyProcessRefundReason == "Damaged")
        #expect(mockOrdersController.spyUpdateOrderID == 456)
        #expect(mockOrdersController.loadOrderRefundsCalled == true)
    }

    @Test func processRefund_when_cash_refund_succeeds_then_opens_the_cash_drawer() async throws {
        // Given
        let drawerService = MockCashDrawerService()
        let cashDrawer = POSCashDrawerController(service: drawerService, userDefaults: try makeUserDefaults())
        let sut = makeModel(cashDrawer: cashDrawer)
        mockRefundController.stubIsCashRefund = true

        // When
        await withCheckedContinuation { continuation in
            drawerService.onOpen = { continuation.resume() }
            Task { try await sut.processRefund(reason: nil) }
        }

        // Then
        #expect(drawerService.openCallCount == 1)
        #expect(cashDrawer.lastEvent?.reason == .cashRefund)
    }

    @Test(arguments: [false, true])
    func test_processRefund_when_cash_refund_succeeds_then_records_created_refund_despite_order_refresh_failure(refreshFails: Bool) async throws {
        // Given
        let cashSessionService = MockPOSCashSessionService()
        mockRefundController.stubRefundedOrderID = 456
        mockRefundController.stubRefundID = 987
        mockRefundController.stubIsCashRefund = true
        mockOrdersController.selectedOrder = makeTestOrder(id: 456, email: "customer@example.com")
        mockOrdersController.shouldThrowError = refreshFails
        let sut = makeModel(cashSessionService: cashSessionService)
        let (recordedRefunds, continuation) = AsyncStream<Int64>.makeStream()
        defer { continuation.finish() }
        cashSessionService.onCashRefundRecorded = { _, refundID in continuation.yield(refundID) }

        // When
        try await sut.processRefund(reason: nil)
        var iterator = recordedRefunds.makeAsyncIterator()
        let recordedRefundID = await iterator.next()

        // Then
        #expect(recordedRefundID == 987)
        #expect(cashSessionService.recordedCashRefunds.count == 1)
        #expect(cashSessionService.recordedCashRefunds.first?.orderID == 456)
        #expect(cashSessionService.recordedCashRefunds.first?.refundID == 987)
        #expect(mockOrdersController.updateOrderCalled)
        #expect(mockOrdersController.loadOrderRefundsCalled)
    }

    @Test func test_processRefund_when_refund_is_not_cash_then_does_not_open_drawer_or_record_cash_refund() async throws {
        // Given
        let drawerService = MockCashDrawerService()
        let cashSessionService = MockPOSCashSessionService()
        let cashDrawer = POSCashDrawerController(service: drawerService, userDefaults: try makeUserDefaults())
        let sut = makeModel(cashDrawer: cashDrawer, cashSessionService: cashSessionService)
        mockRefundController.stubIsCashRefund = false

        // When
        try await sut.processRefund(reason: nil)

        // Then
        #expect(drawerService.openCallCount == 0)
        #expect(cashSessionService.recordedCashRefunds.isEmpty)
    }

    @Test func processRefund_when_order_refresh_fails_then_still_loads_the_refunds() async throws {
        // Given a successful refund whose post-refund order refresh fails
        mockRefundController.stubRefundedOrderID = 456
        mockOrdersController.shouldThrowError = true

        // When
        try await sut.processRefund(reason: nil)

        // Then
        #expect(mockOrdersController.updateOrderCalled == true)
        #expect(mockOrdersController.loadOrderRefundsCalled == true)
    }

    @Test func refundActionAvailability_when_no_order_is_selected_then_unavailable() async throws {
        // Given
        mockOrdersController.selectedOrder = nil

        // When / Then
        #expect(sut.refundActionAvailability == .unavailable)
    }

    @Test func refundActionAvailability_when_a_completed_order_is_selected_then_available() async throws {
        // Given
        mockOrdersController.selectedOrder = makeTestOrder(id: 1, email: "customer@example.com")

        // When / Then
        #expect(sut.refundActionAvailability == .available)
    }

    @Test func processRefund_when_submission_fails_then_throws_without_refreshing_the_order() async throws {
        // Given
        mockRefundController.processRefundErrorToThrow = MockPOSRefundController.TestError.processRefundFailed

        // When & Then
        await #expect(throws: MockPOSRefundController.TestError.processRefundFailed) {
            try await sut.processRefund(reason: nil)
        }
        #expect(mockOrdersController.updateOrderCalled == false)
        #expect(mockOrdersController.loadOrderRefundsCalled == false)
    }

    private func makeModel(cashDrawer: POSCashDrawerController? = nil,
                           cashSessionService: (any POSCashSessionService)? = nil) -> POSOrderListModel {
        POSOrderListModel(
            ordersController: mockOrdersController,
            refundController: mockRefundController,
            receiptSender: mockReceiptSender,
            refundSubmissionModel: POSRefundSubmissionModel(),
            cashDrawer: cashDrawer,
            cashSessionService: cashSessionService
        )
    }

    private func makeUserDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: UUID().uuidString))
    }

    private func makeTestOrder(id: Int64, email: String, refunds: [POSOrderRefund] = []) -> POSOrder {
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
            refunds: refunds,
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$10.00",
            formattedNetAmount: nil,
            datePaid: Date()
        )
    }
}
