import Foundation

public enum CardPresentPaymentResult {
    case success(CardPresentPaymentTransaction)
    case cancellation
}
