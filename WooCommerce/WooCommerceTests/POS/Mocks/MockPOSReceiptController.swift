import Foundation
@testable import WooCommerce
import struct Yosemite.Order

final class MockPOSReceiptController: POSReceiptControllerProtocol {
    var shouldThrowReceiptError: Bool = false
    var sendReceiptWasCalled: Bool = false
    var sendReceiptCalledWithOrder: Order?
    var sendReceiptCalledWithEmail: String?

    func sendReceipt(order: Order, recipientEmail: String) async throws {
        sendReceiptWasCalled = true
        sendReceiptCalledWithOrder = order
        sendReceiptCalledWithEmail = recipientEmail

        if shouldThrowReceiptError {
            throw PointOfSaleOrderController.PointOfSaleOrderControllerError.noOrder
        }
    }
}
