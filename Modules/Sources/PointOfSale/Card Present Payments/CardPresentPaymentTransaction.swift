import Foundation

/// A completed, paid transaction.
public struct CardPresentPaymentTransaction {
    let receiptURL: URL

    public init(receiptURL: URL) {
        self.receiptURL = receiptURL
    }
}
