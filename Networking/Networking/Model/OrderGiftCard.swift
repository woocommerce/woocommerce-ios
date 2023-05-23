import Foundation
import Codegen

/// OrderGiftCard entity: Represents a gift card applied to an order.
///
public struct OrderGiftCard: Codable, Equatable, GeneratedFakeable, GeneratedCopiable {

    /// Remote ID for the gift card
    ///
    public let giftCardID: Int64

    /// Gift card code
    ///
    public let code: String

    /// Amount applied to the order
    ///
    public let amount: Double

    /// OrderGiftCard struct initializer.
    ///
    public init(giftCardID: Int64, code: String, amount: Double) {
        self.giftCardID = giftCardID
        self.code = code
        self.amount = amount
    }
}

/// Defines all of the OrderGiftCard's CodingKeys.
///
private extension OrderGiftCard {

    enum CodingKeys: String, CodingKey {
        case giftCardID = "id"
        case code       = "code"
        case amount     = "amount"
    }
}
