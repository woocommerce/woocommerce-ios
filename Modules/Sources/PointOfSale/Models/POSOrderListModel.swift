import Foundation
import Observation
import struct Yosemite.POSOrder

@Observable final class POSOrderListModel {
    let ordersController: POSSearchingOrderListControllerProtocol
    let receiptSender: POSReceiptSending

    init(ordersController: POSSearchingOrderListControllerProtocol,
         receiptSender: POSReceiptSending) {
        self.ordersController = ordersController
        self.receiptSender = receiptSender
    }

    func loadOrder(orderID: Int64) async throws -> POSOrder {
        try await ordersController.loadOrder(orderID: orderID)
    }

    func sendReceipt(order: POSOrder, email: String) async throws {
        try await receiptSender.sendReceipt(orderID: order.id, recipientEmail: email)
        try await ordersController.updateOrder(orderID: order.id)
    }
}
