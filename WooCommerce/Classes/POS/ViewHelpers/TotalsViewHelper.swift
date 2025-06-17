import Foundation

struct TotalsViewHelper {
    func shouldShowTotalsFields(for paymentState: PointOfSalePaymentState) -> Bool {
        guard paymentState.cash == .idle else {
            return false
        }

        switch paymentState.card {
        case .idle,
                .acceptingCard,
                .cardInserted,
                .validatingOrder,
                .validatingOrderError,
                .paymentIntentCreationError,
                .preparingReader:
            return true
        case .processingPayment,
                .paymentError,
                .cardPaymentSuccessful:
            return false
        }
    }

    func shouldShowDisconnectedMessage(readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
                                       paymentState: PointOfSalePaymentState) -> Bool {
        guard readerConnectionStatus == .disconnected else {
            return false
        }

        guard paymentState.cash == .idle else {
            return false
        }

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

    func shouldShowCollectCashPaymentButton(orderState: PointOfSaleOrderState,
                                            paymentState: PointOfSalePaymentState,
                                            cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus) -> Bool {
        guard orderState != .syncing else {
            return false
        }

        guard paymentState.cash == .idle else {
            return false
        }

        if cardReaderConnectionStatus == .disconnected {
            return true
        }

        if case let .loaded(totals) = orderState, totals.orderTotalDecimal.isZero {
            return true
        }

        switch paymentState.card {
        case .validatingOrderError,
                .paymentIntentCreationError,
             .acceptingCard:
            return true
        default:
            return false
        }
    }

    func shouldApplyPadding(paymentState: PointOfSalePaymentState) -> Bool {
        switch paymentState.cash {
        case .collectingCash, .paymentSuccess:
            return false
        case .idle:
            break
        }

        switch paymentState.card {
        case .cardPaymentSuccessful, .paymentError:
            return false
        default:
            return true
        }
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
