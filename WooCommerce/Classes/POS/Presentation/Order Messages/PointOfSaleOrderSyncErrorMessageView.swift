import SwiftUI

struct PointOfSaleOrderSyncErrorMessageView: View {
    let message: String
    let retryHandler: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                Spacer()
                POSErrorExclamationMark(size: .large)
                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)
                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                    Text(Localization.title)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posHeadingBold)

                    Text(message)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posBodyLargeRegular())
                        .padding([.leading, .trailing])
                }
                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)
                Button(Localization.actionTitle, action: retryHandler)
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
                    .padding([.leading, .trailing], Constants.buttonSidePadding)
                    .padding([.bottom], Constants.buttonBottomPadding)
                Spacer()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private extension PointOfSaleOrderSyncErrorMessageView {
    enum Constants {
        static let buttonSidePadding: CGFloat = POSPadding.xxLarge
        static let buttonBottomPadding: CGFloat = POSPadding.medium
    }
}

private extension PointOfSaleOrderSyncErrorMessageView {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.orderSync.error.title",
            value: "Couldn't load totals",
            comment: "Title of the error when failing to synchronize order and calculate order totals"
        )

        static let actionTitle = NSLocalizedString(
            "pointOfSale.orderSync.error.tryAgain",
            value: "Try again",
            comment: "Button title to retry synchronizing order and calculating order totals"
        )
    }
}

#Preview {
    PointOfSaleOrderSyncErrorMessageView(message: "An error happened!") {}
}
