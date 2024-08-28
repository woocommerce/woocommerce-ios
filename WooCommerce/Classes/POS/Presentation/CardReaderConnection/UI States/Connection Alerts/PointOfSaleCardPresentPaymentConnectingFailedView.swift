import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
                Image(decorative: viewModel.imageName)

                Text(viewModel.title)
                    .font(POSFontStyle.posTitleEmphasized)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if let errorDetails = viewModel.errorDetails {
                    Text(errorDetails)
                        .font(POSFontStyle.posBodyRegular)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            Button(viewModel.retryButtonViewModel.title,
                   action: viewModel.retryButtonViewModel.actionHandler)
            .buttonStyle(POSPrimaryButtonStyle())
        }
        .posModalCloseButton(action: viewModel.cancelButtonViewModel.actionHandler,
                             accessibilityLabel: viewModel.cancelButtonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingFailedView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel(
            error: NSError(domain: "preview.error", code: 1),
            retryButtonAction: {},
            cancelButtonAction: {}))
}
