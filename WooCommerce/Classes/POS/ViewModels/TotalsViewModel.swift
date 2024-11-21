import Foundation

final class TotalsViewModel {
    func shouldShowTotalsFields(for paymentState: PointOfSalePaymentState) -> Bool {
        switch paymentState {
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
    }
}
