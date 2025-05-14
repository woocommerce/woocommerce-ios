import Foundation
@testable import Yosemite

final class MockReceiptService: POSReceiptServiceProtocol {
    var sendReceiptWasCalled: Bool?
    var spyIsEligibleForPOSReceipt: Bool?

    func sendReceipt(order: Yosemite.Order, recipientEmail: String, isEligibleForPOSReceipt: Bool) async throws {
        sendReceiptWasCalled = true
        spyIsEligibleForPOSReceipt = isEligibleForPOSReceipt
    }
}
