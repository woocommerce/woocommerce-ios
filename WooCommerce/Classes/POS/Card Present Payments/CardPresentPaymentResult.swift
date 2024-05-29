import Foundation

enum CardPresentPaymentResult {
    case success(CardPresentPaymentTransaction)
    case cancellation
}
