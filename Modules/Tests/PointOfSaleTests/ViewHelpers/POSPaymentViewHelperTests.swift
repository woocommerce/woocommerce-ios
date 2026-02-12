import Testing
@testable import PointOfSale

struct POSPaymentViewHelperTests {

    @Test(arguments: [
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.acceptingCard),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.idle),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.preparingReader)
    ])
    func test_shouldShowDisconnectedMessage_returns_true_when_disconnected_and_no_card_payment_ongoing(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(POSPaymentViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: readerConnectionStatus,
                                                                         paymentState: PointOfSalePaymentState(card: paymentState, cash: .idle)))
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
            #expect(POSPaymentViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: readerConnectionStatus,
                                                                         paymentState: PointOfSalePaymentState(card: paymentState, cash: .idle)) == false)
    }

    @Test(arguments: [
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.acceptingCard),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.cardPaymentSuccessful),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.idle),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.paymentError),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.preparingReader),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.processingPayment),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.validatingOrder),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.validatingOrderError),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.paymentIntentCreationError),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.cardInserted)
    ])
    func test_shouldShowDisconnectedMessage_returns_false_when_reader_connected(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(POSPaymentViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: readerConnectionStatus,
                                                                         paymentState: PointOfSalePaymentState(card: paymentState, cash: .idle)) == false)
    }
}
