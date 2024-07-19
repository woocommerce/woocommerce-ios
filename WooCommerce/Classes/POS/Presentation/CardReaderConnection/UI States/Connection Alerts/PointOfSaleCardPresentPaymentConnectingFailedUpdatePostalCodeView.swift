import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel

    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            Text(viewModel.errorDetails)

            Button(viewModel.retryButtonViewModel.title,
                   action: viewModel.retryButtonViewModel.actionHandler)
            .buttonStyle(PrimaryButtonStyle())

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel(
            retryButtonAction: {},
            cancelButtonAction: {}))
}
