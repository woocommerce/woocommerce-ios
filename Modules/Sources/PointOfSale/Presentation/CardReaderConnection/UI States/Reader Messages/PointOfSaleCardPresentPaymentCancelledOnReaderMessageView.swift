import SwiftUI

struct PointOfSaleCardPresentPaymentCancelledOnReaderMessageView: View {
    @Environment(\.posMetrics) private var metrics
    let viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(alignment: .center, spacing: metrics.spacing.none) {
            Spacer()

            POSErrorXMark()
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            Spacer()
                .frame(height: metrics.spacing.large)

            VStack(alignment: .center, spacing: metrics.spacing.small) {
                Text(viewModel.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                if let message = viewModel.message {
                    Text(message)
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurface)
                        .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
                }
            }
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
                .frame(height: metrics.spacing.xxLarge)

            VStack(spacing: metrics.spacing.large) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))
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

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentCancelledOnReaderMessageView(
        viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel(tryPaymentAgainButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}
