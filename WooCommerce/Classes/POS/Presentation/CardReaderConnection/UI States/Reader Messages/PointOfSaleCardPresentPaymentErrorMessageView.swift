import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel

    var body: some View {
        HStack {
            VStack {
                Text(viewModel.title)
                Text(viewModel.message)
            }

            Button(viewModel.tryAgainButtonViewModel.title,
                   action: viewModel.tryAgainButtonViewModel.actionHandler)

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            tryAgainButtonAction: {},
            cancelButtonAction: {}))
}
