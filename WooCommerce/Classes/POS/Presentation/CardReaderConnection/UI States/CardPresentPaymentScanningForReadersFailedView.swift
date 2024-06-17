import SwiftUI

struct CardPresentPaymentScanningForReadersFailedView: View {
    private let viewModel: CardPresentPaymentScanningFailedAlertViewModel

    init(viewModel: CardPresentPaymentScanningFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            Text(viewModel.errorDetails)

            Button(viewModel.buttonViewModel.title,
                   action: viewModel.buttonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview {
    CardPresentPaymentScanningForReadersFailedView(
        viewModel: CardPresentPaymentScanningFailedAlertViewModel(
            error: NSError(domain: "", code: 1, userInfo: nil),
            endSearchAction: {}))
}
