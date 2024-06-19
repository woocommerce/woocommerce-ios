import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView(viewModel: .init(cancelUpdateAction: {}))
}
