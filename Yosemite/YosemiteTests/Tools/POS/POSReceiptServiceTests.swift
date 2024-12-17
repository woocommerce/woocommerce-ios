import Testing
import XCTest
@testable import Yosemite

struct POSReceiptServiceTests {
    let sut: POSReceiptService
    let receiptsRemote: MockPOSReceiptsRemote

    init() {
        let receiptsRemote = MockPOSReceiptsRemote()
        self.receiptsRemote = receiptsRemote

        self.sut = POSReceiptService(siteID: 123, receiptsRemote: receiptsRemote)
    }

    @Test
    func sendReceipt_calls_remote_with_correct_parameters() async throws {
        // Given
        let order = Order.fake().copy(orderID: 456)
        let email = "test@example.com"

        // When
        try await sut.sendReceipt(order: order, recipientEmail: email)

        // Then
        #expect(receiptsRemote.sendReceiptCalled)
        #expect(receiptsRemote.spySiteID == 123)
        #expect(receiptsRemote.spyOrderID == 456)
    }

    @Test
    func sendReceipt_when_remote_fails_throws_error() async {
        // Given
        let order = Order.fake()
        receiptsRemote.shouldThrowError = NSError(domain: "test", code: 0)

        // When/Then
        do {
            try await sut.sendReceipt(order: order, recipientEmail: "test@example.com")
            XCTFail("Expected error to be thrown")
        } catch {
            guard case POSReceiptService.POSReceiptServiceError.sendReceiptFailed = error else {
                XCTFail("Expected error .sendReceiptFailed, but got \(error)")
                return
            }
        }
    }
}
