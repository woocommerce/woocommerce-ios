import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool
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
                    .accessibilityFocused($isTitleFocused)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

            VStack(spacing: PointOfSaleCardPresentPaymentLayout.buttonSpacing) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                if let backToCheckoutButtonViewModel = viewModel.backToCheckoutButtonViewModel {
                    Button(backToCheckoutButtonViewModel.title,
                           action: backToCheckoutButtonViewModel.actionHandler)
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                }
            }
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
        .onAppear {
            isTitleFocused = true
        }
    }
}

#Preview("Generic retry") {
    @Previewable @Namespace var namespace

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
    @Previewable @Namespace var namespace

    return PointOfSaleCardPresentPaymentErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            tryAnotherPaymentMethodButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}
