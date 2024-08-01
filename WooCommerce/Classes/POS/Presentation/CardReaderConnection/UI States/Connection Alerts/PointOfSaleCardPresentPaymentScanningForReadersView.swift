import SwiftUI

struct PointOfSaleCardPresentPaymentScanningForReadersView: View {
    private let viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)

            Image(viewModel.imageName)

            Text(viewModel.instruction)

            Button(viewModel.buttonViewModel.title,
                   action: viewModel.buttonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentScanningForReadersView(
        viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel(endSearchAction: {}))
}
