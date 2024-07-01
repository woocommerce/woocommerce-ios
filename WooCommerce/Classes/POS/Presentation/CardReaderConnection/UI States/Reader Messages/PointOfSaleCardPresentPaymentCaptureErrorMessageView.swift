import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentCaptureErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel

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
    PointOfSaleCardPresentPaymentCaptureErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel(
            cancelButtonAction: {}))
}
