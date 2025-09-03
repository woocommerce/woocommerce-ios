import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentNonRetryableErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.none) {
            Spacer()

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

                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                    Text(viewModel.message)
                    Text(viewModel.nextStep)
                }
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurface)
                .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

            Button(viewModel.tryAnotherPaymentMethodButtonViewModel.title,
                   action: viewModel.tryAnotherPaymentMethodButtonViewModel.actionHandler)
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentNonRetryableErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader), tryAnotherPaymentMethodAction: {}),
        animation: .init(namespace: namespace)
    )
}
