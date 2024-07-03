import SwiftUI

struct PointOfSaleCardPresentPaymentCaptureFailedView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text(Localization.title)

            Image(uiImage: .paymentErrorImage)

            Text(Localization.errorDetails)

            Button(Localization.understandButtonTitle,
                   action: {
                dismiss()
            })
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

private extension PointOfSaleCardPresentPaymentCaptureFailedView {
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

        static let understandButtonTitle = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.paymentCaptureError.understand.button.title",
            value: "I understand",
            comment: "Button to dismiss the alert presented when payment capture fails."
        )
    }
}

#Preview {
    PointOfSaleCardPresentPaymentCaptureFailedView()
}
