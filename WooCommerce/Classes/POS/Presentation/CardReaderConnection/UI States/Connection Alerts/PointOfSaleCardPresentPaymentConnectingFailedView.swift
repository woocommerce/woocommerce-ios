import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .accessibilityAddTraits(.isHeader)

            viewModel.image
                .accessibilityHidden(true)

            if let errorDetails = viewModel.errorDetails {
                Text(errorDetails)
            }

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.buttonSpacing) {
                Button(viewModel.retryButtonViewModel.title,
                       action: viewModel.retryButtonViewModel.actionHandler)
                .buttonStyle(PrimaryButtonStyle())

                Button(viewModel.cancelButtonViewModel.title,
                       action: viewModel.cancelButtonViewModel.actionHandler)
                .buttonStyle(SecondaryButtonStyle())
            }
        }
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
