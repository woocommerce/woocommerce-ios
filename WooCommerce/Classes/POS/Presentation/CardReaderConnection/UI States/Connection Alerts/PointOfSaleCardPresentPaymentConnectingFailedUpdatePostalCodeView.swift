import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

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
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel(
            retryButtonAction: {},
            cancelButtonAction: {}))
}
