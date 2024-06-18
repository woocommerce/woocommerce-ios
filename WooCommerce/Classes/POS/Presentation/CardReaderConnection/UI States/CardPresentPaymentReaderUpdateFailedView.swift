import SwiftUI

struct CardPresentPaymentReaderUpdateFailedView: View {
    private let viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel

    init(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

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
    CardPresentPaymentReaderUpdateFailedView(viewModel: .init(retryAction: {}, cancelUpdateAction: {}))
}
