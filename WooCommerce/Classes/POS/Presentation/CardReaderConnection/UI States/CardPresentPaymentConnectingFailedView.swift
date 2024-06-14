import SwiftUI

struct CardPresentPaymentConnectingFailedView: View {
    private let viewModel: CardPresentPaymentConnectingFailedAlertViewModel

    init(viewModel: CardPresentPaymentConnectingFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            if let errorDetails = viewModel.errorDetails {
                Text(errorDetails)
            }

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
    CardPresentPaymentConnectingFailedView(
        viewModel: CardPresentPaymentConnectingFailedAlertViewModel(
            error: NSError(domain: "preview.error", code: 1),
            retryButtonAction: {},
            cancelButtonAction: {}))
}
