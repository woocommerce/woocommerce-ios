import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .accessibilityAddTraits(.isHeader)

            viewModel.image

            Text(viewModel.errorDetails)

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
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel(
            retryButtonAction: {},
            cancelButtonAction: {}))
}
