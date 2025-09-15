import Foundation
import Observation
import struct Yosemite.POSOrder

@Observable final class PointOfSaleOrderListModel {
    let ordersController: PointOfSaleSearchingOrderListControllerProtocol
    let receiptSender: POSReceiptSending

    init(ordersController: PointOfSaleSearchingOrderListControllerProtocol,
         receiptSender: POSReceiptSending) {
        self.ordersController = ordersController
        self.receiptSender = receiptSender
    }

    func sendReceipt(order: POSOrder, email: String) async throws {
        try await receiptSender.sendReceipt(orderID: order.id, recipientEmail: email)
        try await ordersController.updateOrder(orderID: order.id)
    }
}
