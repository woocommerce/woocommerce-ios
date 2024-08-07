import Foundation

struct PointOfSaleCardPresentPaymentSuccessMessageViewModel {
    let title = Localization.title
    let message: String

    init(total: String) {
        message = String(format: Localization.message, total)
    }
}

private extension PointOfSaleCardPresentPaymentSuccessMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.paymentSuccessful.title",
            value: "Payment successful!",
            comment: "Title shown to users when payment is made successfully."
        )

        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.paymentSuccessful.message",
            value: "A payment of %1$@ was successfully made",
            comment: "Message shown to users when payment is made. %1$@ indicates a total sum, e.g $10.5"
        )
    }
}
