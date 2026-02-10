import Foundation
import SwiftUI
import WooFoundation

struct TotalsViewHelper {
    /// Shared background color for payment views (cart and bookings).
    func paymentBackgroundColor(for paymentState: PointOfSalePaymentState) -> Color {
        switch paymentState.activePaymentMethod {
        case .cash:
            switch paymentState.cash {
            case .collectingCash, .paymentSuccess:
                return .posSurfaceBright
            default:
                return .clear
            }
        case .card:
            switch paymentState.card {
            case .processingPayment:
                return .posPrimary
            case .cardPaymentSuccessful:
                return .posSurfaceBright
            default:
                return .clear
            }
        }
    }

    /// Base cash payment button visibility (without order state checks).
    /// Used by bookings flow. Cart flow uses `shouldShowCollectCashPaymentButton` which adds order state guards.
    func shouldShowCashPaymentButton(paymentState: PointOfSalePaymentState,
                                     cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus) -> Bool {
        switch paymentState.activePaymentMethod {
        case .cash:
            return false
        case .card:
            if case .disconnected = cardReaderConnectionStatus,
               case .idle = paymentState.card {
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
    }
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

    /// Cash payment button visibility for the cart flow (adds order state guards on top of the base check).
    func shouldShowCollectCashPaymentButton(orderState: PointOfSaleOrderState,
                                            paymentState: PointOfSalePaymentState,
                                            cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus) -> Bool {
        guard orderState != .syncing else {
            return false
        }

        // Cart-specific: show button for zero-total orders (only when card method is active)
        if case .card = paymentState.activePaymentMethod,
           case let .loaded(totals) = orderState,
           totals.orderTotalDecimal.isZero {
            return true
        }

        return shouldShowCashPaymentButton(paymentState: paymentState,
                                           cardReaderConnectionStatus: cardReaderConnectionStatus)
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
