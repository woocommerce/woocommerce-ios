import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentNonRetryableErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .font(.posBody)

                Text(viewModel.message)
                    .font(.posTitle)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .bold()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentNonRetryableErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader)))
}
