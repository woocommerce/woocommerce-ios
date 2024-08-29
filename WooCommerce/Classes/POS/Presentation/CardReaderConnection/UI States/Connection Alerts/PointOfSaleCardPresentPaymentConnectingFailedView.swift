import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

            if let errorDetails = viewModel.errorDetails {
                Text(errorDetails)
                    .font(POSFontStyle.posBodyRegular)
            }

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
