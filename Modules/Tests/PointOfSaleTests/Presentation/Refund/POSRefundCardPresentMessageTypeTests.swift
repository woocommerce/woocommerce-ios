import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSRefundCardPresentMessageTypeTests {
    @Test
    func test_isStatusScreen_when_refund_is_cancelled_on_reader_then_returns_true() {
        let messageType = POSRefundCardPresentMessageType.cancelledOnReader(.cancelledOnReader(backToRefund: {}))

        #expect(messageType.isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_refund_fails_then_returns_true() {
        let messageType = POSRefundCardPresentMessageType.error(.init(error: NSError(domain: "test", code: 1),
                                                                      retryAction: {},
                                                                      cancelAction: {}))

        #expect(messageType.isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_refund_is_processing_then_returns_false() {
        let messageType = POSRefundCardPresentMessageType.processing(.processing)

        #expect(!messageType.isStatusScreen)
    }

    @Test
    func test_isStatusScreen_when_reader_is_preparing_then_returns_false() {
        let messageType = POSRefundCardPresentMessageType.preparingReader(.checkingRefund)

        #expect(!messageType.isStatusScreen)
    }
}
