import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)

            viewModel.image

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView(viewModel: .init(cancelUpdateAction: {}))
}
