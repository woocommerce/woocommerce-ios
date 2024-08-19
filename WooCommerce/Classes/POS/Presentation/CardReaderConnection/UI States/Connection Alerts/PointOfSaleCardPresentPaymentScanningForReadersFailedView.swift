import SwiftUI

struct PointOfSaleCardPresentPaymentScanningForReadersFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .accessibilityAddTraits(.isHeader)

            viewModel.image
                .accessibilityHidden(true)

            Text(viewModel.errorDetails)

            Button(viewModel.buttonViewModel.title,
                   action: viewModel.buttonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
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
