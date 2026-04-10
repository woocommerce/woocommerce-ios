import Networking

final class MockPOSReceiptsRemote: POSReceiptsRemoteProtocol {
    var sendReceiptCalled = false
    var sendPOSReceiptCalled = false
    var spySiteID: Int64?
    var spyOrderID: Int64?
    var spyEmail: String?
    var spyTemplateID: String?
    var shouldThrowError: Error?

    func sendReceipt(siteID: Int64, orderID: Int64) async throws {
        sendReceiptCalled = true
        spySiteID = siteID
        spyOrderID = orderID

        if let shouldThrowError {
            throw shouldThrowError
        }
    }

    func sendPOSReceipt(siteID: Int64, orderID: Int64, emailAddress: String, templateID: String?) async throws {
        sendPOSReceiptCalled = true
        spySiteID = siteID
        spyOrderID = orderID
        spyEmail = emailAddress
        spyTemplateID = templateID

        if let shouldThrowError {
            throw shouldThrowError
        }
    }
}
