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

    @Test(arguments: [
        (PointOfSaleOrderState.idle, PointOfSalePaymentState.card(.idle)),
        (PointOfSaleOrderState.idle, PointOfSalePaymentState.card(.validatingOrderError)),
        (PointOfSaleOrderState.idle, PointOfSalePaymentState.card(.preparingReader)),
        (PointOfSaleOrderState.idle, PointOfSalePaymentState.card(.acceptingCard))
    ])
    func test_shouldShowCollectCashPaymentButton_returns_true_for_supported_states(
        orderState: PointOfSaleOrderState,
        paymentState: PointOfSalePaymentState) {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: orderState,
                                                                         paymentState: paymentState))
    }

    @Test(arguments: [
        (PointOfSaleOrderState.syncing, PointOfSalePaymentState.card(.idle)),
        (PointOfSaleOrderState.syncing, PointOfSalePaymentState.card(.validatingOrderError)),
        (PointOfSaleOrderState.syncing, PointOfSalePaymentState.card(.preparingReader)),
        (PointOfSaleOrderState.syncing, PointOfSalePaymentState.card(.acceptingCard))
    ])
    func test_shouldShowCollectCashPaymentButton_returns_false_when_order_syncing(
        orderState: PointOfSaleOrderState,
        paymentState: PointOfSalePaymentState) {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: orderState,
                                                                         paymentState: paymentState) == false)
    }
}
