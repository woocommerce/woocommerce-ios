import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            Button(viewModel.retryButtonViewModel.title,
                   action: viewModel.retryButtonViewModel.actionHandler)
            .buttonStyle(PrimaryButtonStyle())

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderUpdateFailedView(viewModel: .init(retryAction: {}, cancelUpdateAction: {}))
}
