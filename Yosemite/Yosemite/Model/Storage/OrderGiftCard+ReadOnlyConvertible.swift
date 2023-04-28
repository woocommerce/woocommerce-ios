import Foundation
import Storage


// MARK: - Storage.OrderGiftCard: ReadOnlyConvertible
//
extension Storage.OrderGiftCard: ReadOnlyConvertible {

    /// Updates the Storage.OrderGiftCard with the ReadOnly.
    ///
    public func update(with giftCard: Yosemite.OrderGiftCard) {
        giftCardID = giftCard.giftCardID
        code = giftCard.code
        amount = giftCard.amount
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderGiftCard {
        OrderGiftCard(giftCardID: giftCardID,
                      code: code ?? "",
                      amount: amount)
    }
}
