import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentNonRetryableErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel

    var body: some View {
        POSCardPresentPaymentMessageView(viewModel: .init(title: viewModel.title,
                                                          message: viewModel.message))
    }
}

#Preview {
    PointOfSaleCardPresentPaymentNonRetryableErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader)))
}
