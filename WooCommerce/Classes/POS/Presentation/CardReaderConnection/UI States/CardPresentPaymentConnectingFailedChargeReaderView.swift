import SwiftUI

struct CardPresentPaymentConnectingFailedChargeReaderView: View {
    let viewModel: CardPresentPaymentConnectingFailedChargeReaderAlertViewModel
    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            Text(viewModel.errorDetails)

            Button(viewModel.retryButtonViewModel.title,
                   action: viewModel.retryButtonViewModel.actionHandler)

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview {
    CardPresentPaymentConnectingFailedChargeReaderView(
        viewModel: CardPresentPaymentConnectingFailedChargeReaderAlertViewModel(
            retryButtonAction: {},
            cancelButtonAction: {}))
}
