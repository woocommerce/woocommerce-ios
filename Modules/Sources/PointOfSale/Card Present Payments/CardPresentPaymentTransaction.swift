import Foundation
import struct Yosemite.CardPresentTransactionDetails

/// A completed, paid transaction.
public struct CardPresentPaymentTransaction: Sendable {
    public let cardDetails: CardPresentTransactionDetails?

    public init(cardDetails: CardPresentTransactionDetails? = nil) {
        self.cardDetails = cardDetails
    }
}
