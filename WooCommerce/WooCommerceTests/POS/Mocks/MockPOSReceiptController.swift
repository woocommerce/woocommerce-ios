import Foundation
@testable import WooCommerce
import struct Yosemite.Order

final class MockPOSReceiptController: POSReceiptControllerProtocol {
    var shouldThrowReceiptError: Bool = false
    var sendReceiptWasCalled: Bool = false
    var sendReceiptCalledWithOrderID: Int64?
    var sendReceiptCalledWithEmail: String?

    func sendReceipt(orderID: Int64, recipientEmail: String) async throws {
        sendReceiptWasCalled = true
        sendReceiptCalledWithOrderID = orderID
        sendReceiptCalledWithEmail = recipientEmail

        if shouldThrowReceiptError {
            throw PointOfSaleOrderController.PointOfSaleOrderControllerError.noOrder
        }
    }
}
