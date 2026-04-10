import Foundation
import struct Hardware.CardPresentReceiptParameters

/// A completed, paid transaction.
public struct CardPresentPaymentTransaction {
    public let receiptURL: URL?
    public let receiptParameters: CardPresentReceiptParameters?

    public init(receiptURL: URL? = nil,
                receiptParameters: CardPresentReceiptParameters? = nil) {
        self.receiptURL = receiptURL
        self.receiptParameters = receiptParameters
    }
}
