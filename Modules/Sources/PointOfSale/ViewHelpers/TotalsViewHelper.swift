import Foundation

/// Cart-specific view helper methods used only by TotalsView.
struct TotalsViewHelper {
    private let paymentViewHelper = POSPaymentViewHelper()

    func shouldShowReconnectingMessage(readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
                                       paymentState: PointOfSalePaymentState) -> Bool {
        guard case .reconnecting = readerConnectionStatus else {
            return false
        }

        switch paymentState.activePaymentMethod {
        case .cash, .scanToPay, .markAsPaid:
            return false
        case .card:
            switch paymentState.card {
            case .idle,
                    .acceptingCard,
                    .preparingReader:
                return true
            case .validatingOrder,
                    .validatingOrderError,
                    .paymentIntentCreationError,
                    .processingPayment,
                    .cardInserted,
                    .paymentError,
                    .cardPaymentSuccessful:
                return false
            }
        }
    }

    /// Cash payment button visibility for the cart flow (adds order state guards on top of the base check).
    func shouldShowCollectCashPaymentButton(orderState: PointOfSaleOrderState,
                                            paymentState: PointOfSalePaymentState,
                                            cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus) -> Bool {
        guard orderState != .syncing else {
            return false
        }

        if case .reconnecting = cardReaderConnectionStatus {
            return false
        }

        let isZeroTotal: Bool = if case let .loaded(totals) = orderState {
            totals.orderTotalDecimal.isZero
        } else {
            false
        }

        return paymentViewHelper.shouldShowCashPaymentButton(paymentState: paymentState,
                                                             cardReaderConnectionStatus: cardReaderConnectionStatus,
                                                             isZeroTotal: isZeroTotal)
    }

    /// Checkout payment methods for a store where card-present payments are disabled
    /// (unsupported country, or Canada pending Interac). Cash is the primary CTA; the
    /// "Other payment methods" entry is appended only when at least one such method exists.
    func noCardCheckoutPaymentMethods(hasOtherPaymentMethodsAvailable: Bool) -> [POSCheckoutPaymentMethod] {
        var methods: [POSCheckoutPaymentMethod] = [.cashPayment]
        if hasOtherPaymentMethodsAvailable {
            methods.append(.otherPaymentMethods)
        }
        return methods
    }

    /// On a no-card store the iPad side panel renders the Cash + "Other payment methods"
    /// strip, while the phone uses the stacked button row instead. So the strip applies
    /// only at regular width, and only when there's an Other-methods entry to pair with Cash.
    func useNoCardCashAndOtherMethodsStrip(isRegularWidth: Bool, hasOtherPaymentMethodsAvailable: Bool) -> Bool {
        isRegularWidth && hasOtherPaymentMethodsAvailable
    }

    /// Whether a non-card payment (cash / scan-to-pay / mark-as-paid) has succeeded.
    /// On no-card stores neither the Tap to Pay hero nor the card payment view renders,
    /// so the success view must take over the upper region off this signal — otherwise
    /// the merchant lands on an empty screen after a successful non-card payment.
    func hasNonCardPaymentSucceeded(paymentState: PointOfSalePaymentState) -> Bool {
        paymentState.cash == .paymentSuccess
            || paymentState.scanToPay == .paymentSuccess
            || paymentState.markAsPaid == .paymentSuccess
    }

    func shouldShowTotalDiscountField(cart: Cart, orderTotals: PointOfSaleOrderTotals?) -> Bool {
        let hasCoupons = cart.coupons.isNotEmpty
        let orderIsLoading = orderTotals == nil
        let hasDiscounts = orderTotals?.discountTotal != nil

        guard hasCoupons else {
            return false
        }

        return orderIsLoading || hasDiscounts
    }

    func shouldShowCustomAmountsField(cart: Cart, orderTotals: PointOfSaleOrderTotals?) -> Bool {
        let hasCustomAmounts = cart.customAmounts.isNotEmpty
        let orderIsLoading = orderTotals == nil
        let hasCustomAmountsTotal = orderTotals?.customAmountsTotal != nil

        guard hasCustomAmounts else {
            return false
        }

        return orderIsLoading || hasCustomAmountsTotal
    }
}
