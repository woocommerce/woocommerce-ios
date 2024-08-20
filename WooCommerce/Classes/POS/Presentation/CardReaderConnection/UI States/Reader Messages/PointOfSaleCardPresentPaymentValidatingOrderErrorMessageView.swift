import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorExclamationMark()
            VStack(alignment: .center, spacing: Constants.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .font(.posTitleEmphasized)

                Text(viewModel.message)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .font(.posBodyRegular)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let tryAgainButtonViewModel = viewModel.tryAgainButtonViewModel {
                Button(tryAgainButtonViewModel.title, action: tryAgainButtonViewModel.actionHandler)
                    .buttonStyle(POSPrimaryButtonStyle())
            }
        }
        .padding(.horizontal, PointOfSaleCardPresentPaymentLayout.horizontalPadding)
        .multilineTextAlignment(.center)
    }
}

private extension PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView {
    enum Constants {
        static let textSpacing: CGFloat = 16
    }
}

#Preview {
    PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            retryApproach: .tryAgain(retryAction: {})))
}
