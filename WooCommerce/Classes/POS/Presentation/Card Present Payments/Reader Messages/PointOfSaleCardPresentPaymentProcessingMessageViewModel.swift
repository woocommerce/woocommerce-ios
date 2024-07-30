import Foundation

struct PointOfSaleCardPresentPaymentProcessingMessageViewModel {
    let imageName = PointOfSaleAssets.posProcessingPaymentImageName
    let title = Localization.paymentProcessing
}

private extension PointOfSaleCardPresentPaymentProcessingMessageViewModel {
    enum Localization {
        static let paymentProcessing = NSLocalizedString(
            "pointOfSale.cardPresent.paymentProcessing.title",
            value: "Processing payment",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )
    }
}
