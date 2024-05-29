import Foundation

enum CardPresentPaymentResult {
    case success(POSTransaction)
    case cancellation
}
