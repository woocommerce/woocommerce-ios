import Foundation
@testable import Yosemite

final class MockReceiptService: POSReceiptServiceProtocol {
    var sendReceiptWasCalled: Bool?
    var spyIsEligibleForPOSReceipt: Bool?
    var sendReceiptResult: Result<Void, Error> = .success(())

    func sendReceipt(order: Yosemite.Order, recipientEmail: String, isEligibleForPOSReceipt: Bool) async throws {
        sendReceiptWasCalled = true
        spyIsEligibleForPOSReceipt = isEligibleForPOSReceipt
        switch sendReceiptResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
