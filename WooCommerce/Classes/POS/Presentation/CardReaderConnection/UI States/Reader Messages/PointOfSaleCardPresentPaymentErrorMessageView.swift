import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel

    var body: some View {
        VStack(alignment: .center) {
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .font(.posBody)

                Text(viewModel.message)
                    .font(.posTitle)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .bold()
            }

            HStack {
                Button(viewModel.tryAgainButtonViewModel.title, action: viewModel.tryAgainButtonViewModel.actionHandler)
            }
            .padding()
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            tryAgainButtonAction: {}))
}
