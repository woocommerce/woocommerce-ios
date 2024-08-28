import SwiftUI

struct PointOfSaleCardPresentPaymentScanningForReadersView: View {
    private let viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Image(decorative: viewModel.imageName)

            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(viewModel.instruction)
                .font(POSFontStyle.posBodyRegular)
                .fixedSize(horizontal: false, vertical: true)
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
