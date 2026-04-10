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
        try await sut.sendReceipt(orderID: order.orderID, recipientEmail: email, isEligibleForPOSReceipt: false, templateID: nil)

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
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com", isEligibleForPOSReceipt: false, templateID: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            guard case POSReceiptService.POSReceiptServiceError.sendReceiptFailed = error else {
                XCTFail("Expected error .sendReceiptFailed, but got \(error)")
                return
            }
        }
    }

    @Test
    func sendReceipt_calls_remote_when_isEligibleForPOSReceipt_is_true() async throws {
        // Given
        let email = "test@example.com"
        let orderID: Int64 = 789

        // When
        try await sut.sendReceipt(orderID: orderID, recipientEmail: email, isEligibleForPOSReceipt: true, templateID: "some_template")

        // Then
        #expect(receiptsRemote.sendPOSReceiptCalled)
        #expect(receiptsRemote.spySiteID == 123)
        #expect(receiptsRemote.spyOrderID == orderID)
        #expect(receiptsRemote.spyEmail == email)
        #expect(receiptsRemote.spyTemplateID == "some_template")
    }

    @Test
    func sendReceipt_when_templateID_is_nil_passes_nil_to_remote() async throws {
        // Given
        let email = "test@example.com"
        let orderID: Int64 = 789

        // When
        try await sut.sendReceipt(orderID: orderID, recipientEmail: email, isEligibleForPOSReceipt: true, templateID: nil)

        // Then
        #expect(receiptsRemote.sendPOSReceiptCalled)
        #expect(receiptsRemote.spyTemplateID == nil)
    }
}
