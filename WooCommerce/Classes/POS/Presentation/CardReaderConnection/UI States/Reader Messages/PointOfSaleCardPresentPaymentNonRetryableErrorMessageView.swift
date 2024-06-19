import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentNonRetryableErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel

    var body: some View {
        HStack {
            VStack {
                Text(viewModel.title)
                Text(viewModel.message)
            }

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentNonRetryableErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            cancelButtonAction: {}))
}
