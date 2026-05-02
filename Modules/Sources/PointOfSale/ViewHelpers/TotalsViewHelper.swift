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
        case .cash:
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

    /// "Other payment methods" button visibility for the cart flow.
    /// Shown only when at least one of the secondary payment-method feature flags is enabled —
    /// otherwise the sheet would have no rows to render. Otherwise mirrors the cash button rules.
    func shouldShowOtherPaymentMethodsButton(orderState: PointOfSaleOrderState,
                                             paymentState: PointOfSalePaymentState,
                                             cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus,
                                             isAnySecondaryPaymentMethodEnabled: Bool) -> Bool {
        guard isAnySecondaryPaymentMethodEnabled else {
            return false
        }

        // Reuse the cash button's order-state and connection guards — the visibility envelope is
        // identical for both buttons (we want them to appear/disappear together).
        return shouldShowCollectCashPaymentButton(orderState: orderState,
                                                   paymentState: paymentState,
                                                   cardReaderConnectionStatus: cardReaderConnectionStatus)
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
}
