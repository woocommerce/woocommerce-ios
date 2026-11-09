import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentNonRetryableErrorMessageView: View {
    @Environment(\.posMetrics) private var metrics
    let viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State private var width: CGFloat = 0

    var body: some View {
        POSStatusScreenLayout {
            VStack(alignment: .center, spacing: metrics.spacing.none) {
                POSErrorXMark()
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                Spacer()
                    .frame(height: metrics.spacing.large)

                VStack(alignment: .center, spacing: metrics.spacing.small) {
                    Text(viewModel.title)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posHeadingBold)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($isTitleFocused)
                        .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                    VStack(alignment: .center, spacing: metrics.spacing.small) {
                        Text(viewModel.message)
                        Text(viewModel.nextStep)
                    }
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
                }
                .dynamicWidthScaling(containerWidth: width)
            }
        } buttons: {
            Button(viewModel.tryAnotherPaymentMethodButtonViewModel.title,
                   action: viewModel.tryAnotherPaymentMethodButtonViewModel.actionHandler)
            .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
        .multilineTextAlignment(.center)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
        .onAppear {
            isTitleFocused = true
        }
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
