import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSRefundCardPresentMessageTypeTests {
    @Test
    func test_isStatusScreen_when_refund_is_cancelled_on_reader_then_returns_true() {
        // Given
        let messageType = POSRefundCardPresentMessageType.cancelledOnReader(.cancelledOnReader(backToRefund: {}))

        // When / Then
        #expect(messageType.isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_refund_fails_then_returns_true() {
        // Given
        let messageType = POSRefundCardPresentMessageType.error(.init(error: NSError(domain: "test", code: 1),
                                                                      retryAction: {},
                                                                      cancelAction: {}))

        // When / Then
        #expect(messageType.isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_refund_is_processing_then_returns_false() {
        // Given
        let messageType = POSRefundCardPresentMessageType.processing(.processing)

        // When / Then
        #expect(!messageType.isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_reader_is_preparing_then_returns_false() {
        // Given
        let messageType = POSRefundCardPresentMessageType.preparingReader(.checkingRefund)

        // When / Then
        #expect(!messageType.isStatusScreen)
    }
}
