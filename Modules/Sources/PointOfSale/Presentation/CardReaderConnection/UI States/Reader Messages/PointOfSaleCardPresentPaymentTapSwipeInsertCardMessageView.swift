import SwiftUI

struct PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView: View {
    @Environment(\.posMetrics) private var metrics
    let viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isMessageFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .center, spacing: metrics.spacing.xLarge) {
            POSCardPresentPaymentMessageViewImage(imageName: viewModel.imageName)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
                .renderedIf(!dynamicTypeSize.isAccessibilitySize)
            VStack(alignment: .center, spacing: metrics.spacing.small) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .font(.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isMessageFocused)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityIdentifier("pos-card-payment-message")
        .onAppear {
            isMessageFocused = true
        }
    }
}

#Preview {
    return PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView(
        viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel(
            inputMethods: [.tap, .insert]
        ),
        animation: .init(namespace: Namespace().wrappedValue)
    )
}
