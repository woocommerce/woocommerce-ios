import Foundation
import WooFoundation

struct TotalsViewHelper {
    func shouldShowTotalsFields(for paymentState: PointOfSalePaymentState) -> Bool {
        switch paymentState.activePaymentMethod {
        case .cash:
            return false
        case .card:
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
    }

    func shouldShowDisconnectedMessage(readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
                                       paymentState: PointOfSalePaymentState) -> Bool {
        guard readerConnectionStatus == .disconnected else {
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
                    .paymentError,
                    .preparingReader:
                return true
            case .validatingOrder,
                    .validatingOrderError,
                    .paymentIntentCreationError,
                    .processingPayment,
                    .cardInserted,
                    .cardPaymentSuccessful:
                return false
            }
        }
    }

    func shouldShowCollectCashPaymentButton(orderState: PointOfSaleOrderState,
                                            paymentState: PointOfSalePaymentState,
                                            cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus) -> Bool {
        guard orderState != .syncing else {
            return false
        }

        if case .reconnecting = cardReaderConnectionStatus {
            return false
        }

        switch paymentState.activePaymentMethod {
        case .cash:
            return false
        case .card:
            if case .disconnected = cardReaderConnectionStatus,
                case .idle = paymentState.card {
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
            case .idle,
                    .cardInserted,
                    .validatingOrder,
                    .preparingReader,
                    .processingPayment,
                    .paymentError,
                    .cardPaymentSuccessful:
                return false
            }
        }
    }

    func shouldApplyPadding(paymentState: PointOfSalePaymentState) -> Bool {
        switch paymentState.activePaymentMethod {
        case .cash:
            return false
        case .card:
            switch paymentState.card {
            case .cardPaymentSuccessful, .paymentError:
                return false
            case .idle,
                    .acceptingCard,
                    .cardInserted,
                    .validatingOrder,
                    .validatingOrderError,
                    .paymentIntentCreationError,
                    .preparingReader,
                    .processingPayment:
                return true
            }
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
