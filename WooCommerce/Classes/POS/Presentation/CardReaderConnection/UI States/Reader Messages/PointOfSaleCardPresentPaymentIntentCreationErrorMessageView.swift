import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentIntentCreationErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorXMark()
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }

            VStack(spacing: PointOfSaleCardPresentPaymentLayout.buttonSpacing) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                if let editOrderButtonViewModel = viewModel.editOrderButtonViewModel {
                    Button(editOrderButtonViewModel.title,
                           action: editOrderButtonViewModel.actionHandler)
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: PointOfSaleCardPresentPaymentLayout.errorContentMaxWidth)
    }
}

#Preview {
    @Namespace var namespace

    return PointOfSaleCardPresentPaymentIntentCreationErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            tryPaymentAgainButtonAction: {},
            editOrderButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}
