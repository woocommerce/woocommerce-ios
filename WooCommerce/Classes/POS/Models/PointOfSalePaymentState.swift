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
