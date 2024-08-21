import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentNonRetryableErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorXMark()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.primaryText)
                    .font(.posTitleEmphasized)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.smallTextSpacing) {
                    Text(viewModel.message)
                    Text(viewModel.nextStep)
                }
                .font(.posBodyRegular)
                .foregroundStyle(Color.primaryText)
            }

            Button(viewModel.tryAnotherPaymentMethodButtonViewModel.title,
                   action: viewModel.tryAnotherPaymentMethodButtonViewModel.actionHandler)
            .buttonStyle(POSPrimaryButtonStyle())
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: PointOfSaleCardPresentPaymentLayout.errorContentMaxWidth)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentNonRetryableErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader), tryAnotherPaymentMethodAction: {}))
}
