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
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.validatingOrderError),
        (CardPresentPaymentReaderConnectionStatus.connected(.init(name: "", batteryLevel: nil)), PointOfSaleCardPaymentState.cardInserted)
    ])
    func test_shouldShowDisconnectedMessage_returns_false_when_reader_connected(
        readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
        paymentState: PointOfSaleCardPaymentState) {
            #expect(TotalsViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: readerConnectionStatus,
                                                                     paymentState: paymentState) == false)
    }

    @Test(arguments: [
        (PointOfSalePaymentState.card(.validatingOrderError)),
        (PointOfSalePaymentState.card(.acceptingCard)),
        (PointOfSalePaymentState.card(.cardInserted))
    ])
    func test_shouldShowCollectCashPaymentButton_returns_true_for_supported_states(
        paymentState: PointOfSalePaymentState) {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 0)),
                                                                          paymentState: paymentState,
                                                                          cardReaderConnectionStatus: .connected(.init(name: "", batteryLevel: nil))))
    }

    @Test
    func test_shouldShowCollectCashPaymentButton_returns_true_for_idle_when_reader_disconnected() {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 0)),
                                                                          paymentState: .card(.idle),
                                                                          cardReaderConnectionStatus: .disconnected))
    }

    @Test
    func test_shouldShowCollectCashPaymentButton_returns_true_for_idle_when_reader_connected_but_order_zero() {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "0",
                                                                                                    orderTotal: "0",
                                                                                                    taxTotal: "0",
                                                                                                    orderTotalDecimal: 0)),
                                                                          paymentState: .card(.idle),
                                                                          cardReaderConnectionStatus: .connected(.init(name: "", batteryLevel: nil))))
    }

    @Test
    func test_shouldShowCollectCashPaymentButton_returns_false_for_idle_when_reader_connected_but_order_not_zero() {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .loaded(.init(cartTotal: "10",
                                                                                                    orderTotal: "10",
                                                                                                    taxTotal: "10",
                                                                                                    orderTotalDecimal: 10)),
                                                                          paymentState: .card(.idle),
                                                                          cardReaderConnectionStatus: .connected(.init(name: "", batteryLevel: nil))) == false)
    }

    @Test(arguments: [
        (PointOfSalePaymentState.card(.validatingOrderError)),
        (PointOfSalePaymentState.card(.acceptingCard)),
        (PointOfSalePaymentState.card(.cardInserted))
    ])
    func test_shouldShowCollectCashPaymentButton_returns_false_when_order_syncing(
        paymentState: PointOfSalePaymentState) {
            #expect(TotalsViewHelper().shouldShowCollectCashPaymentButton(orderState: .syncing,
                                                                         paymentState: paymentState,
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
        cart.add(.coupon(.init(id: .init(), code: "TEST10", summary: "")))

        #expect(TotalsViewHelper().shouldShowTotalDiscountField(cart: cart, orderTotals: nil))
    }

    @Test
    func test_shouldShowTotalDiscountField_returns_true_when_cart_has_coupons_and_orderTotals_with_discount() {
        var cart = Cart()
        cart.add(.coupon(.init(id: .init(), code: "TEST10", summary: "")))
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
        cart.add(.coupon(.init(id: .init(), code: "TEST10", summary: "")))
        let orderTotals = PointOfSaleOrderTotals(cartTotal: "10",
                                                 orderTotal: "10",
                                                 taxTotal: "0",
                                                 orderTotalDecimal: 10)

        #expect(TotalsViewHelper().shouldShowTotalDiscountField(cart: cart, orderTotals: orderTotals) == false)
    }
}
