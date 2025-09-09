import Foundation
import Observation
import struct Yosemite.POSOrder

@Observable final class PointOfSaleOrderListModel {
    let ordersController: PointOfSaleSearchingOrderListControllerProtocol
    let receiptController: POSReceiptControllerProtocol

    init(ordersController: PointOfSaleSearchingOrderListControllerProtocol,
         receiptController: POSReceiptControllerProtocol) {
        self.ordersController = ordersController
        self.receiptController = receiptController
    }

    func sendReceipt(order: POSOrder, email: String) async throws {
        try await receiptController.sendReceipt(orderID: order.id, recipientEmail: email)
    }
}
