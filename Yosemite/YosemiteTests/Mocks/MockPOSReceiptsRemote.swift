import Networking

final class MockPOSReceiptsRemote: POSReceiptsRemoteProtocol {
    var sendReceiptCalled = false
    var spySiteID: Int64?
    var spyOrderID: Int64?
    var shouldThrowError: Error?

    func sendReceipt(siteID: Int64, orderID: Int64) async throws {
        sendReceiptCalled = true
        spySiteID = siteID
        spyOrderID = orderID

        if let shouldThrowError {
            throw shouldThrowError
        }
    }
}
