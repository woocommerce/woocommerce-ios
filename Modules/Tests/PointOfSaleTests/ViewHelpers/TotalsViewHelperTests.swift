import Testing
@testable import PointOfSale
import struct Yosemite.POSItemIdentifier

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
}
