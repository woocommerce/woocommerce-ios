import Foundation
@testable import Yosemite

final class MockReceiptService: POSReceiptServiceProtocol {
    var sendReceiptWasCalled: Bool?
    var spyIsEligibleForPOSReceipt: Bool?
    var spyTemplateID: String?
    var sendReceiptResult: Result<Void, Error> = .success(())

    func sendReceipt(orderID: Int64, recipientEmail: String, isEligibleForPOSReceipt: Bool, templateID: String?) async throws {
        sendReceiptWasCalled = true
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
