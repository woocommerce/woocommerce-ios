import Foundation
import Observation
import struct Yosemite.POSOrder

/// Coordinates the two controllers behind the orders screen: the order list and the refund flow.
/// Everything that spans both — starting a refund for the selected order, resetting the flow when
/// the selection changes, refreshing the order after a refund — belongs here, so neither controller
/// has to know about the other.
@Observable final class POSOrderListModel {
    let ordersController: POSSearchingOrderListControllerProtocol
    let refundController: POSRefundControllerProtocol
    let receiptSender: POSReceiptSending
    let refundSubmissionModel: POSRefundSubmissionModel

    init(ordersController: POSSearchingOrderListControllerProtocol,
         refundController: POSRefundControllerProtocol,
         receiptSender: POSReceiptSending,
         refundSubmissionModel: POSRefundSubmissionModel) {
        self.ordersController = ordersController
        self.refundController = refundController
        self.receiptSender = receiptSender
        self.refundSubmissionModel = refundSubmissionModel
    }

    func sendReceipt(order: POSOrder, email: String) async throws {
        try await receiptSender.sendReceipt(orderID: order.id, recipientEmail: email)
        try await ordersController.updateOrder(orderID: order.id)
    }

    @MainActor
    func selectOrder(_ order: POSOrder?) {
        ordersController.selectOrder(order)
        refundController.reset()
    }

    @MainActor
    func preloadRefund() async {
        guard let order = ordersController.selectedOrder else {
            return
        }
        await refundController.preloadRefund(for: order)
    }

    @MainActor
    func startRefundFlow() async -> StartRefundFlowResult {
        guard let order = ordersController.selectedOrder else {
            return .failed
        }
        return await refundController.startRefundFlow(for: order)
    }

    @MainActor
    func processRefund(reason: String?) async throws {
        let orderID = try await refundController.processRefund(reason: reason)
        try? await ordersController.updateOrder(orderID: orderID)
        await ordersController.loadOrderRefunds()
    }
}
