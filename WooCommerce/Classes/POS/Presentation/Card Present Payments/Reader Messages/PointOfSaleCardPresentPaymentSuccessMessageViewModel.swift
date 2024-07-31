import Foundation

struct PointOfSaleCardPresentPaymentSuccessMessageViewModel {
    let imageName = PointOfSaleAssets.paymentSuccessful.imageName
    let title = Localization.paymentSuccessful
}

private extension PointOfSaleCardPresentPaymentSuccessMessageViewModel {
    enum Localization {
        static let paymentSuccessful = NSLocalizedString(
            "pointOfSale.cardPresent.paymentSuccessful.title",
            value: "Payment successful!",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )
    }
}
