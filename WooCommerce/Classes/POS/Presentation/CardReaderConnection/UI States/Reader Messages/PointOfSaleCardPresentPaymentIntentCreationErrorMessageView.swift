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
                    .foregroundStyle(Color.posPrimaryText)
                    .font(.posTitleEmphasized)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posBodyRegular)
                    .foregroundStyle(Color.posPrimaryText)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }

            VStack(spacing: PointOfSaleCardPresentPaymentLayout.buttonSpacing) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSPrimaryButtonStyle())

                if let editOrderButtonViewModel = viewModel.editOrderButtonViewModel {
                    Button(editOrderButtonViewModel.title,
                           action: editOrderButtonViewModel.actionHandler)
                    .buttonStyle(POSSecondaryButtonStyle())
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
