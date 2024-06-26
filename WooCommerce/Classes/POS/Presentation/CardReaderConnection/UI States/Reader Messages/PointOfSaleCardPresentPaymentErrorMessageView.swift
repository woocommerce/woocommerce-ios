import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel

    var body: some View {
        POSCardPresentPaymentMessageView(viewModel: .init(title: viewModel.title,
                                                          message: viewModel.message,
                                                          buttons: [
                                                            viewModel.tryAgainButtonViewModel,
                                                            viewModel.cancelButtonViewModel
                                                          ]))
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
