import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentIntentCreationErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            POSErrorXMark()
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)

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

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

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
            .frame(width: width * 0.5)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: PointOfSaleCardPresentPaymentLayout.errorContentMaxWidth)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
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
