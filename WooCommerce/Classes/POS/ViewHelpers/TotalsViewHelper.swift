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
                                            paymentState: PointOfSalePaymentState) -> Bool {
        orderState != .syncing &&
        (paymentState == .card(.idle) || paymentState == .card(.acceptingCard) || paymentState == .card(.validatingOrderError))
    }
}
