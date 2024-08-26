import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posBodyRegular)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

            Text(viewModel.errorDetails)
                .font(POSFontStyle.posDetailLight)

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.buttonSpacing) {
                Button(viewModel.retryButtonViewModel.title,
                       action: viewModel.retryButtonViewModel.actionHandler)
                .buttonStyle(PrimaryButtonStyle())

                Button(viewModel.cancelButtonViewModel.title,
                       action: viewModel.cancelButtonViewModel.actionHandler)
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel(
            retryButtonAction: {},
            cancelButtonAction: {}))
}
