import SwiftUI

struct PointOfSaleCardPresentPaymentCaptureFailedView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorExclamationMark()
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(Localization.title)
                    .foregroundStyle(Color.posPrimaryText)
                    .font(.posTitleEmphasized)

                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.smallTextSpacing) {
                    Text(Localization.message)
                    Text(Localization.nextSteps)
                }
                .font(.posBodyRegular)
                .foregroundStyle(Color.posPrimaryText)
            }

            Button(Localization.understandButtonTitle,
                   action: {
                isPresented = false
            })
            .buttonStyle(POSPrimaryButtonStyle())
        }
        .multilineTextAlignment(.center)
        .padding(Layout.contentPadding)
        .frame(maxWidth: Layout.maxWidth)
    }
}

private extension PointOfSaleCardPresentPaymentCaptureFailedView {
    enum Layout {
        static let maxWidth: CGFloat = 896
        static let contentPadding: CGFloat = 40
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.paymentCaptureError.order.may.have.failed.title",
            value: "This order may have failed",
            comment: "Title of the alert presented when payment capture may have failed. This draws extra " +
            "attention to the issue."
        )

        static let message = NSLocalizedString(
            "pointOfSale.cardPresentPayment.paymentCaptureError.order.may.have.failed.message",
            value: "Due to a network error, we don’t know if payment succeeded.",
            comment: "Message drawing attention to issue of payment capture maybe failing."
        )

        static let nextSteps = NSLocalizedString(
            "pointOfSale.cardPresentPayment.paymentCaptureError.order.may.have.failed.nextSteps",
            value: "Please double check the order on a device with a network connection before continuing.",
            comment: ""
        )

        static let understandButtonTitle = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.paymentCaptureError.understand.button.title",
            value: "I understand",
            comment: "Button to dismiss the alert presented when payment capture fails."
        )
    }
}

#Preview {
    PointOfSaleCardPresentPaymentCaptureFailedView(isPresented: .constant(true))
}
