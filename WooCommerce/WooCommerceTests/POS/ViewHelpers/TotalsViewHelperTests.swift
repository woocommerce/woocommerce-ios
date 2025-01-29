import Testing
@testable import WooCommerce

struct TotalsViewHelperTests {

    @Test(arguments: [
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.acceptingCard),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.idle),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.preparingReader)
    ])
    func test_shouldShowDisconnectedMessage_returns_true_when_disconnected_and_no_card_payment_ongoing(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: readerConnectionStatus,
                                                                     paymentState: paymentState))
    }

    @Test(arguments: [
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.cardPaymentSuccessful),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.paymentError),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.processingPayment),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.validatingOrder),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.validatingOrderError)
    ])
    func test_shouldShowDisconnectedMessage_returns_false_when_card_payment_ongoing(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: readerConnectionStatus,
                                                                     paymentState: paymentState) == false)
    }

    @Test(arguments: [
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.acceptingCard),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.cardPaymentSuccessful),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.idle),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.paymentError),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.preparingReader),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.processingPayment),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.validatingOrder),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.validatingOrderError)
    ])
    func test_shouldShowDisconnectedMessage_returns_false_when_reader_connected(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: readerConnectionStatus,
                                                                     paymentState: paymentState) == false)
    }

}
