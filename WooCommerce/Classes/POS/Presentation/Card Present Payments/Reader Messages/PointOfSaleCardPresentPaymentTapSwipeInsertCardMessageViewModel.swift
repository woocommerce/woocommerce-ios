import Foundation
import struct Yosemite.CardReaderInput

struct PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel {
    let imageName = "pos-ready-for-payment"
    let title = Localization.readyForPayment
    let message: String

    init(inputMethods: CardReaderInput) {
        self.message = Self.message(for: inputMethods)
    }

    private static func message(for inputMethods: CardReaderInput) -> String {
        if inputMethods == [.swipe, .insert, .tap] {
            return Localization.tapInsertOrSwipe
        } else if inputMethods == [.tap, .insert] {
            return Localization.tapOrInsert
        } else if inputMethods.contains(.tap) {
            return Localization.tap
        } else if inputMethods.contains(.insert) {
            return Localization.insert
        } else {
            return Localization.presentCard
        }
    }
}

private extension PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel {
    enum Localization {
        static let readyForPayment = NSLocalizedString(
            "pointOfSale.cardPresent.presentCard.title",
            value: "Ready for payment",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )

        static let tapInsertOrSwipe = NSLocalizedString(
            "pointOfSale.cardPresent.presentCard.tapSwipeInsert",
            value: "Tap, insert or swipe to pay",
            comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
        )

        static let tapOrInsert = NSLocalizedString(
            "pointOfSale.cardPresent.presentCard.tapInsert",
            value: "Tap or insert card to pay",
            comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
        )

        static let tap = NSLocalizedString(
            "pointOfSale.cardPresent.presentCard.tap",
            value: "Tap card to pay",
            comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
        )

        static let insert = NSLocalizedString(
            "pointOfSale.cardPresent.presentCard.insert",
            value: "Insert card to pay",
            comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
        )

        static let presentCard = NSLocalizedString(
            "pointOfSale.cardPresent.presentCard.present",
            value: "Present card to pay",
            comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
        )
    }
}
