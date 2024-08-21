import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedNonRetryableView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .accessibilityAddTraits(.isHeader)

            viewModel.image
                .accessibilityHidden(true)

            Text(viewModel.errorDetails)

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingFailedNonRetryableView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel(
            error: NSError(domain: "payments error", code: 1),
            cancelAction: {}))
}
