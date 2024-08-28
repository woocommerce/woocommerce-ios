import SwiftUI

struct PointOfSaleCardPresentPaymentScanningForReadersFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Image(decorative: viewModel.imageName)

            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(viewModel.errorDetails)
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
    PointOfSaleCardPresentPaymentScanningForReadersFailedView(
        viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel(
            error: NSError(domain: "", code: 1, userInfo: nil),
            endSearchAction: {}))
}
