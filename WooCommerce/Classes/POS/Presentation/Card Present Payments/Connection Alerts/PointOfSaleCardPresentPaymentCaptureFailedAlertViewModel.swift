import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentCaptureFailedAlertViewModel {
    let title = Localization.title
    let image = Image(uiImage: .paymentErrorImage)
    let errorDetails = Localization.errorDetails
    let cancelButtonTitle = Localization.cancel
}

private extension PointOfSaleCardPresentPaymentCaptureFailedAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.paymentCaptureError.title",
            value: "Please check order payment status",
            comment: "Title of the alert presented when payment capture fails."
        )

        static let errorDetails = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.paymentCaptureError.errorDetails",
            value: "Due to an error from capturing payment and refreshing order, we couldn't load complete order information. " +
            "To avoid undercharging or double charging, please check the latest order separately before proceeding.",
            comment: "Subtitle of the alert presented when payment capture fails."
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.paymentCaptureError.cancel.button.title",
            value: "I understand that order should be checked",
            comment: "Button to dismiss the alert presented when payment capture fails."
        )
    }
}
