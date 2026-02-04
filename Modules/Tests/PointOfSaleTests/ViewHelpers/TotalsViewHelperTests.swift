import Testing
@testable import PointOfSale
import struct Yosemite.POSItemIdentifier

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
            #expect(TotalsViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: readerConnectionStatus,
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
            #expect(TotalsViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: readerConnectionStatus,
                                                                     paymentState: PointOfSalePaymentState(card: paymentState, cash: .idle)) == false)
    }

    @Test(arguments: [
        (PointOfSaleCardPaymentState.validatingOrderError),
        (PointOfSaleCardPaymentState.acceptingCard),
        (PointOfSaleCardPaymentState.cardInserted),
        (PointOfSaleCardPaymentState.paymentIntentCreationError)
    ])
    func test_shouldShowCollectCashPaymentButton_returns_true_for_supported_states(
        cardPaymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 0)),
                                                                          paymentState: PointOfSalePaymentState(card: cardPaymentState, cash: .idle),
                                                                          cardReaderConnectionStatus: .connected(.init(name: "", batteryLevel: nil))))
    }

    @Test
    func test_shouldShowCollectCashPaymentButton_returns_true_for_idle_when_reader_disconnected() {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 0)),
                                                                          paymentState: PointOfSalePaymentState(card: .idle, cash: .idle),
                                                                          cardReaderConnectionStatus: .disconnected))
    }

    @Test
    func test_shouldShowCollectCashPaymentButton_returns_true_for_idle_when_reader_connected_but_order_zero() {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "0",
                                                                                                    orderTotal: "0",
                                                                                                    taxTotal: "0",
                                                                                                    orderTotalDecimal: 0)),
                                                                          paymentState: PointOfSalePaymentState(card: .idle, cash: .idle),
                                                                          cardReaderConnectionStatus: .connected(.init(name: "", batteryLevel: nil))))
    }

    @Test
    func test_shouldShowCollectCashPaymentButton_returns_false_for_idle_when_reader_connected_but_order_not_zero() {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 10)),
                                                                          paymentState: PointOfSalePaymentState(card: .idle, cash: .idle),
                                                                          cardReaderConnectionStatus: .connected(.init(name: "", batteryLevel: nil))) == false)
    }

    @Test(arguments: [PointOfSaleCardPaymentState.cardInserted,
         PointOfSaleCardPaymentState.validatingOrder,
         PointOfSaleCardPaymentState.preparingReader,
         PointOfSaleCardPaymentState.processingPayment,
         PointOfSaleCardPaymentState.paymentError,
         PointOfSaleCardPaymentState.cardPaymentSuccessful])
    func test_shouldShowCollectCashPaymentButton_returns_false_when_reader_disconnected_for_unsupported_states(
        cardPaymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 10)),
                                                                          paymentState: PointOfSalePaymentState(card: cardPaymentState, cash: .idle),
                                                                          cardReaderConnectionStatus: .disconnected) == false)
    }

    @Test(arguments: [
        (PointOfSaleCardPaymentState.validatingOrderError),
        (PointOfSaleCardPaymentState.acceptingCard),
        (PointOfSaleCardPaymentState.cardInserted)
    ])
    func test_shouldShowCollectCashPaymentButton_returns_false_when_order_syncing(
        cardPaymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .syncing,
                                                                         paymentState: PointOfSalePaymentState(card: cardPaymentState, cash: .idle),
                                                                          cardReaderConnectionStatus: .connected(.init(name: "", batteryLevel: nil))) == false)
    }

    @Test func test_shouldShowCollectCashPaymentButton_returns_false_when_cash_collecting() {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 0)),
                                                                          paymentState: PointOfSalePaymentState(card: .idle, cash: .collectingCash),
                                                                          cardReaderConnectionStatus: .connected(.init(name: "", batteryLevel: nil))) == false)
    }

    @Test func test_shouldShowCollectCashPaymentButton_returns_false_when_cash_payment_success() {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 0)),
                                                                          paymentState: PointOfSalePaymentState(card: .idle, cash: .paymentSuccess),
                                                                          cardReaderConnectionStatus: .connected(.init(name: "", batteryLevel: nil))) == false)
    }

    @Test
    func test_shouldShowTotalDiscountField_returns_false_when_cart_has_no_coupons() {
        let cart = Cart()
        let orderTotals = PointOfSaleOrderTotals(cartTotal: "10",
                                                 orderTotal: "10",
                                                 taxTotal: "0",
                                                 orderTotalDecimal: 10,
                                                 discountTotal: "2")

        #expect(TotalsViewHelper().shouldShowTotalDiscountField(cart: cart, orderTotals: orderTotals) == false)
    }

    @Test
    func test_shouldShowTotalDiscountField_returns_true_when_cart_has_coupons_order_syncing() {
        var cart = Cart()
        cart.add(.coupon(.init(id: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "TEST10", summary: "")))

        #expect(TotalsViewHelper().shouldShowTotalDiscountField(cart: cart, orderTotals: nil))
    }

    @Test
    func test_shouldShowTotalDiscountField_returns_true_when_cart_has_coupons_and_orderTotals_with_discount() {
        var cart = Cart()
        cart.add(.coupon(.init(id: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "TEST10", summary: "")))
        let orderTotals = PointOfSaleOrderTotals(cartTotal: "10",
                                                 orderTotal: "8",
                                                 taxTotal: "0",
                                                 orderTotalDecimal: 8,
                                                 discountTotal: "2")

        #expect(TotalsViewHelper().shouldShowTotalDiscountField(cart: cart, orderTotals: orderTotals))
    }

    @Test
    func test_shouldShowTotalDiscountField_returns_false_when_cart_has_coupons_and_orderTotals_without_discount() {
        var cart = Cart()
        cart.add(.coupon(.init(id: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "TEST10", summary: "")))
        let orderTotals = PointOfSaleOrderTotals(cartTotal: "10",
                                                 orderTotal: "10",
                                                 taxTotal: "0",
                                                 orderTotalDecimal: 10)

        #expect(TotalsViewHelper().shouldShowTotalDiscountField(cart: cart, orderTotals: orderTotals) == false)
    }

    // MARK: - shouldShowReconnectingMessage tests

    @Test(arguments: [
        (CardPresentPaymentReaderConnectionStatus.reconnecting(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.idle),
        (CardPresentPaymentReaderConnectionStatus.reconnecting(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.acceptingCard),
        (CardPresentPaymentReaderConnectionStatus.reconnecting(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.preparingReader)
    ])
    func test_shouldShowReconnectingMessage_returns_true_when_reconnecting_and_payment_not_actively_processing(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowReconnectingMessage(readerConnectionStatus: readerConnectionStatus,
                                                                     paymentState: PointOfSalePaymentState(card: paymentState, cash: .idle)))
    }

    @Test(arguments: [
        (CardPresentPaymentReaderConnectionStatus.reconnecting(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.cardPaymentSuccessful),
        (CardPresentPaymentReaderConnectionStatus.reconnecting(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.paymentError),
        (CardPresentPaymentReaderConnectionStatus.reconnecting(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.processingPayment),
        (CardPresentPaymentReaderConnectionStatus.reconnecting(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.validatingOrder),
        (CardPresentPaymentReaderConnectionStatus.reconnecting(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.validatingOrderError)
    ])
    func test_shouldShowReconnectingMessage_returns_false_when_card_payment_ongoing(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowReconnectingMessage(readerConnectionStatus: readerConnectionStatus,
                                                                     paymentState: PointOfSalePaymentState(card: paymentState, cash: .idle)) == false)
    }

    @Test(arguments: [
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.idle),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.acceptingCard),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.preparingReader)
    ])
    func test_shouldShowReconnectingMessage_returns_false_when_reader_connected(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowReconnectingMessage(readerConnectionStatus: readerConnectionStatus,
                                                                     paymentState: PointOfSalePaymentState(card: paymentState, cash: .idle)) == false)
    }

    @Test(arguments: [
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.idle),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.acceptingCard),
        (CardPresentPaymentReaderConnectionStatus.disconnected, PointOfSaleCardPaymentState.preparingReader)
    ])
    func test_shouldShowReconnectingMessage_returns_false_when_reader_disconnected(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowReconnectingMessage(readerConnectionStatus: readerConnectionStatus,
                                                                     paymentState: PointOfSalePaymentState(card: paymentState, cash: .idle)) == false)
    }

    // MARK: - shouldShowCollectCashPaymentButton reconnecting tests

    @Test(arguments: [
        PointOfSaleCardPaymentState.idle,
        PointOfSaleCardPaymentState.acceptingCard,
        PointOfSaleCardPaymentState.validatingOrderError,
        PointOfSaleCardPaymentState.paymentIntentCreationError
    ])
    func test_shouldShowCollectCashPaymentButton_returns_false_when_reconnecting(
        cardPaymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 10)),
                                                                          paymentState: PointOfSalePaymentState(card: cardPaymentState, cash: .idle),
                                                                          cardReaderConnectionStatus: .reconnecting(.init(name: "", batteryLevel: nil))) == false)
    }
}
