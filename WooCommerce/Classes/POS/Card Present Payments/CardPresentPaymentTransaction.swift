import Foundation

/// A completed, paid transaction.
struct CardPresentPaymentTransaction {
    let receiptURL: URL
    let paymentData: CardPresentCapturedPaymentData
}
