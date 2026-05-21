import Foundation
import Observation
import struct Yosemite.POSOrder

@Observable final class POSOrderListModel {
    let ordersController: POSSearchingOrderListControllerProtocol
    let receiptSender: POSReceiptSending
    let refundSubmissionModel: POSRefundSubmissionModel

    init(ordersController: POSSearchingOrderListControllerProtocol,
         receiptSender: POSReceiptSending,
         refundSubmissionModel: POSRefundSubmissionModel) {
        self.ordersController = ordersController
        self.receiptSender = receiptSender
        self.refundSubmissionModel = refundSubmissionModel
    }

    func sendReceipt(order: POSOrder, email: String) async throws {
        try await receiptSender.sendReceipt(orderID: order.id, recipientEmail: email)
        try await ordersController.updateOrder(orderID: order.id)
    }
}
