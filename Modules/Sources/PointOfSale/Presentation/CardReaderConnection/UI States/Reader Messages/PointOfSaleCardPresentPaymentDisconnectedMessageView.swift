import SwiftUI

/// Reader-not-connected message shown in the totals view's payment area.
///
/// Quieter "no reader" state — the merchant's actual call to action lives in the
/// bottom payment-method row (`POSCheckoutPaymentButtonsRow`), which renders a
/// "Card reader" entry that triggers the connect flow when no reader is connected.
/// This view used to host its own "Connect your reader" CTA, but moving it into
/// the row keeps method selection in one place and avoids two competing CTAs.
struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    private let viewModel = PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel()
    private let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool
    @ScaledMetric private var scale: CGFloat = 1.0

    init(animation: POSCardPresentPaymentInLineMessageAnimation) {
        self.animation = animation
    }

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.none) {
            POSCardPresentPaymentMessageViewImage(imageName: PointOfSaleAssets.readerDisconnected.imageName)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            Spacer()
                .frame(height: dynamicSpacing(PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing))

            VStack(alignment: .center, spacing: dynamicSpacing(PointOfSaleCardPresentPaymentLayout.textSpacing)) {
                Text(viewModel.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.instruction)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
            .padding(.horizontal, PointOfSaleCardPresentPaymentLayout.horizontalPadding)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .onAppear {
            isTitleFocused = true
        }
    }

    private func dynamicSpacing(_ spacing: CGFloat) -> CGFloat {
        guard scale > 1 else {
            return spacing
        }

        return spacing * (1 / scale)
    }
}

#if DEBUG
#Preview {
    @Previewable @Namespace var namespace
    PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(
        animation: .init(namespace: namespace))
}
#endif
