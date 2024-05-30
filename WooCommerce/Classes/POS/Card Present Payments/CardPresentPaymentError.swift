import Foundation

enum CardPresentPaymentError: Error {
    var retryApproach: CardPaymentRetryApproach {
        .restart
    }

    case unknownPaymentError(underlyingError: Error)
    case unknownConnectionError(UnderlyingError: Error)
}
