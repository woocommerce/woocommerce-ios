import Foundation

enum PointOfSalePaymentState {
    case idle
    case acceptingCard
    case validatingOrder
    case validatingOrderError
    case preparingReader
    case processingPayment
    case paymentError
    case cardPaymentSuccessful
}

extension PointOfSalePaymentState {
    var shownFullScreen: Bool {
        switch self {
        case .processingPayment,
                .paymentError,
                .cardPaymentSuccessful:
            return true
        case .idle,
                .validatingOrder,
                .validatingOrderError,
                .preparingReader,
                .acceptingCard:
            return false
        }
    }
}
