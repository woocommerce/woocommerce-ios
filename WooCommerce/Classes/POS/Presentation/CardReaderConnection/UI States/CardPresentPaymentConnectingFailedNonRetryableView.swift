import SwiftUI

struct CardPresentPaymentConnectingFailedNonRetryableView: View {
    let viewModel: CardPresentPaymentConnectingFailedNonRetryableAlertViewModel
    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            Text(viewModel.errorDetails)

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview {
    CardPresentPaymentConnectingFailedNonRetryableView(
        viewModel: CardPresentPaymentConnectingFailedNonRetryableAlertViewModel(
            error: NSError(domain: "payments error", code: 1),
            cancelAction: {}))
}
