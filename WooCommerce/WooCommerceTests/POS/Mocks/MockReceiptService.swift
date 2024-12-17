import Foundation
@testable import Yosemite

class MockReceiptService: POSReceiptServiceProtocol {
    var sendReceiptWasCalled = false

    func sendReceipt(order: Yosemite.Order, recipientEmail: String) async throws {
        sendReceiptWasCalled = true
    }
}
