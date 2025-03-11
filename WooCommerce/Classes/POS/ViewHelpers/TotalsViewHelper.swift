import Foundation

final class TotalsViewHelper {
    func shouldShowTotalsFields(for paymentState: PointOfSalePaymentState) -> Bool {
        switch paymentState {
        case .card(let cardPaymentState):
            switch cardPaymentState {
            case .idle,
                    .acceptingCard,
                    .validatingOrder,
                    .validatingOrderError,
                    .preparingReader:
                return true
            case .processingPayment,
                    .paymentError,
                    .cardPaymentSuccessful:
                return false
            }
        case .cash:
            return false
        }
    }

    func shouldShowDisconnectedMessage(readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
                                       paymentState: PointOfSaleCardPaymentState) -> Bool {
        guard readerConnectionStatus == .disconnected else {
            return false
        }
        switch paymentState {
        case .idle,
                .acceptingCard,
                .preparingReader:
            return true
        case .validatingOrder,
                .validatingOrderError,
                .processingPayment,
                .paymentError,
                .cardPaymentSuccessful:
            return false
        }
    }

    func shouldShowCollectCashPaymentButton(orderState: PointOfSaleOrderState,
                                            paymentState: PointOfSalePaymentState,
                                            cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus) -> Bool {
        guard orderState != .syncing,
              case .card(let cardState) = paymentState else {
            return false
        }

        if cardReaderConnectionStatus == .disconnected {
            return true
        }

        if case let .loaded(totals) = orderState, totals.orderTotalDecimal.isZero {
            return true
        }

        switch cardState {
        case .validatingOrderError,
             .acceptingCard:
            return true
        default:
            return false
        }
    }

    func shouldApplyPadding(paymentState: PointOfSalePaymentState) -> Bool {
        switch paymentState {
        case .card(.cardPaymentSuccessful), .cash(.paymentSuccess), .cash(.collectingCash), .card(.paymentError):
            return false
        default:
            return true
        }
    }
}
