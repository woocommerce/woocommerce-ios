import Foundation
@testable import PointOfSale
import struct Yosemite.Order

final class MockPOSReceiptSender: POSReceiptSending {
    var sendReceiptErrorToThrow: Error?
    var sendReceiptWasCalled: Bool = false
    var sendReceiptCalledWithOrderID: Int64?
    var sendReceiptCalledWithEmail: String?

    enum TestError: Error {
        case sendReceiptFailed
    }

    func sendReceipt(orderID: Int64, recipientEmail: String) async throws {
        sendReceiptWasCalled = true
        sendReceiptCalledWithOrderID = orderID
        sendReceiptCalledWithEmail = recipientEmail

        if let sendReceiptErrorToThrow {
            throw sendReceiptErrorToThrow
        }
    }
}
