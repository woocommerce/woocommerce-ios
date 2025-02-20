import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing) {
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
            }

            VStack(spacing: PointOfSaleCardPresentPaymentLayout.buttonSpacing) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .frame(width: width * 0.5)

                if let backToCheckoutButtonViewModel = viewModel.backToCheckoutButtonViewModel {
                    Button(backToCheckoutButtonViewModel.title,
                           action: backToCheckoutButtonViewModel.actionHandler)
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                    .frame(width: width * 0.5)
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: PointOfSaleCardPresentPaymentLayout.errorContentMaxWidth)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
    }
}

#Preview("Generic retry") {
    @Namespace var namespace

    return PointOfSaleCardPresentPaymentErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            tryPaymentAgainButtonAction: {},
            backToCheckoutButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}

#Preview("Retry with another payment method") {
    @Namespace var namespace

    return PointOfSaleCardPresentPaymentErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            tryAnotherPaymentMethodButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}
