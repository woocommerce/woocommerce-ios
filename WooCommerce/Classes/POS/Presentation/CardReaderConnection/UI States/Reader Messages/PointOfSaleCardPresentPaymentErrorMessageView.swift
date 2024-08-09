import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorExclamationMark()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.primaryText)
                    .font(.posTitle)

                Text(viewModel.message)
                    .font(.posBody)
                    .foregroundStyle(Color.primaryText)
            }

            VStack(spacing: PointOfSaleCardPresentPaymentLayout.buttonSpacing) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSPrimaryButtonStyle())

                if let exitButtonViewModel = viewModel.exitButtonViewModel {
                    Button(exitButtonViewModel.title,
                           action: exitButtonViewModel.actionHandler)
                    .buttonStyle(POSSecondaryButtonStyle())
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: PointOfSaleCardPresentPaymentLayout.errorContentMaxWidth)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            tryAgainButtonAction: {}))
}
