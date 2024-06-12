import SwiftUI

struct CardPresentPaymentScanningForReadersView: View {
    private let viewModel: CardPresentPaymentScanningForReadersAlertViewModel

    init(viewModel: CardPresentPaymentScanningForReadersAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)
            viewModel.image
            Text(viewModel.instruction)
            Button(viewModel.buttonViewModel.title,
                   action: viewModel.buttonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview {
    CardPresentPaymentScanningForReadersView(
        viewModel: CardPresentPaymentScanningForReadersAlertViewModel(endSearchAction: {}))
}
