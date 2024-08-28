import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedNonRetryableView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel

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
        .posModalCloseButton(action: viewModel.cancelButtonViewModel.actionHandler,
                             accessibilityLabel: viewModel.cancelButtonViewModel.title)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingFailedNonRetryableView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel(
            error: NSError(domain: "payments error", code: 1),
            cancelAction: {}))
}
