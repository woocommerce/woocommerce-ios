import SwiftUI

struct PointOfSaleCardPresentPaymentScanningForReadersView: View {
    private let viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

            Text(viewModel.instruction)
                .font(POSFontStyle.posBodyRegular)
        }
        .posModalCloseButton(action: viewModel.buttonViewModel.actionHandler,
                             accessibilityLabel: viewModel.buttonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentScanningForReadersView(
        viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel(endSearchAction: {}))
}
