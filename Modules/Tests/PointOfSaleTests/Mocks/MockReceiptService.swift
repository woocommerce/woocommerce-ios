import Foundation
@testable import Yosemite

final class MockReceiptService: POSReceiptServiceProtocol {
    var sendReceiptWasCalled: Bool?
    var spyIsEligibleForPOSReceipt: Bool?
    var spyTemplateID: String?
    var spyOrderID: Int64?
    var spyRecipientEmail: String?
    var sendReceiptResult: Result<Void, Error> = .success(())

    func sendReceipt(orderID: Int64, recipientEmail: String, isEligibleForPOSReceipt: Bool, templateID: String?) async throws {
        sendReceiptWasCalled = true
        spyOrderID = orderID
        spyRecipientEmail = recipientEmail
        spyIsEligibleForPOSReceipt = isEligibleForPOSReceipt
        spyTemplateID = templateID
        switch sendReceiptResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
