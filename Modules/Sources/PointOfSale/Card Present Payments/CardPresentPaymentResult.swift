import Foundation

public enum CardPresentPaymentResult: Sendable {
    case success(CardPresentPaymentTransaction)
    case cancellation
}
