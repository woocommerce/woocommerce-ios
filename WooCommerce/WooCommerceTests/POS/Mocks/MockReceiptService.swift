import Foundation
@testable import Yosemite

final class MockReceiptService: POSReceiptServiceProtocol {
    var sendReceiptWasCalled = false

    func sendReceipt(order: Yosemite.Order, recipientEmail: String) async throws {
        sendReceiptWasCalled = true
    }

    func sendReceipt(order: Yosemite.Order, recipientEmail: String, isEligibleForPOSReceipt: Bool) async throws {
    }
}
