import Testing
@testable import PointOfSale
import struct Yosemite.POSItemIdentifier
import struct Yosemite.POSCustomAmount

struct TotalsViewHelperTests {

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

    // MARK: - shouldShowCustomAmountsField tests

    @Test
    func test_shouldShowCustomAmountsField_returns_false_when_cart_has_no_custom_amounts() {
        // Given
        let cart = Cart()
        let orderTotals = PointOfSaleOrderTotals(cartTotal: "10",
                                                 orderTotal: "10",
                                                 taxTotal: "0",
                                                 orderTotalDecimal: 10,
                                                 customAmountsTotal: nil)

        // When / Then
        #expect(TotalsViewHelper().shouldShowCustomAmountsField(cart: cart, orderTotals: orderTotals) == false)
    }

    @Test
    func test_shouldShowCustomAmountsField_returns_true_when_cart_has_custom_amounts_and_order_syncing() {
        // Given
        var cart = Cart()
        cart.upsertCustomAmount(POSCustomAmount(name: "Service fee", amount: "25", isTaxable: true))

        // When / Then
        #expect(TotalsViewHelper().shouldShowCustomAmountsField(cart: cart, orderTotals: nil))
    }

    @Test
    func test_shouldShowCustomAmountsField_returns_true_when_cart_has_custom_amounts_and_orderTotals_with_custom_amounts() {
        // Given
        var cart = Cart()
        cart.upsertCustomAmount(POSCustomAmount(name: "Service fee", amount: "25", isTaxable: true))
        let orderTotals = PointOfSaleOrderTotals(cartTotal: "0",
                                                 orderTotal: "26.25",
                                                 taxTotal: "1.25",
                                                 orderTotalDecimal: 26.25,
                                                 customAmountsTotal: "25")

        // When / Then
        #expect(TotalsViewHelper().shouldShowCustomAmountsField(cart: cart, orderTotals: orderTotals))
    }

    @Test
    func test_shouldShowCustomAmountsField_returns_false_when_cart_has_custom_amounts_but_orderTotals_without_custom_amounts() {
        // Given
        var cart = Cart()
        cart.upsertCustomAmount(POSCustomAmount(name: "Service fee", amount: "25", isTaxable: true))
        let orderTotals = PointOfSaleOrderTotals(cartTotal: "0",
                                                 orderTotal: "0",
                                                 taxTotal: "0",
                                                 orderTotalDecimal: 0,
                                                 customAmountsTotal: nil)

        // When / Then
        #expect(TotalsViewHelper().shouldShowCustomAmountsField(cart: cart, orderTotals: orderTotals) == false)
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

    // MARK: - noCardCheckoutPaymentMethods tests

    @Test
    func test_noCardCheckoutPaymentMethods_when_other_methods_available_then_returns_cash_and_other() {
        #expect(TotalsViewHelper().noCardCheckoutPaymentMethods(hasOtherPaymentMethodsAvailable: true)
                == [.cashPayment, .otherPaymentMethods])
    }

    @Test
    func test_noCardCheckoutPaymentMethods_when_no_other_methods_available_then_returns_cash_only() {
        #expect(TotalsViewHelper().noCardCheckoutPaymentMethods(hasOtherPaymentMethodsAvailable: false)
                == [.cashPayment])
    }

    // MARK: - useNoCardCashAndOtherMethodsStrip tests

    @Test
    func test_useNoCardCashAndOtherMethodsStrip_when_regular_width_and_other_methods_then_true() {
        #expect(TotalsViewHelper().useNoCardCashAndOtherMethodsStrip(isRegularWidth: true,
                                                                     hasOtherPaymentMethodsAvailable: true))
    }

    @Test
    func test_useNoCardCashAndOtherMethodsStrip_when_compact_width_then_false() {
        #expect(TotalsViewHelper().useNoCardCashAndOtherMethodsStrip(isRegularWidth: false,
                                                                     hasOtherPaymentMethodsAvailable: true) == false)
    }

    @Test
    func test_useNoCardCashAndOtherMethodsStrip_when_no_other_methods_then_false() {
        #expect(TotalsViewHelper().useNoCardCashAndOtherMethodsStrip(isRegularWidth: true,
                                                                     hasOtherPaymentMethodsAvailable: false) == false)
    }

    // MARK: - hasNonCardPaymentSucceeded tests

    @Test(arguments: [
        PointOfSalePaymentState(card: .idle, cash: .paymentSuccess),
        PointOfSalePaymentState(card: .idle, cash: .idle, scanToPay: .paymentSuccess),
        PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .paymentSuccess)
    ])
    func test_hasNonCardPaymentSucceeded_when_non_card_method_succeeds_then_true(paymentState: PointOfSalePaymentState) {
        #expect(TotalsViewHelper().hasNonCardPaymentSucceeded(paymentState: paymentState))
    }

    @Test
    func test_hasNonCardPaymentSucceeded_when_all_idle_then_false() {
        #expect(TotalsViewHelper().hasNonCardPaymentSucceeded(paymentState: .idle) == false)
    }

    @Test
    func test_hasNonCardPaymentSucceeded_when_only_card_payment_succeeds_then_false() {
        #expect(TotalsViewHelper().hasNonCardPaymentSucceeded(
            paymentState: PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle)) == false)
    }
}
