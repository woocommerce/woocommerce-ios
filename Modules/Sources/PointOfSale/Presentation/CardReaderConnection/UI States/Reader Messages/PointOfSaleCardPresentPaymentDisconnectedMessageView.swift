import SwiftUI

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    private let viewModel = PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel()
    private let connectCardReader: () -> Void
    private let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool
    @ScaledMetric private var scale: CGFloat = 1.0

    @State private var width: CGFloat = 0

    init(animation: POSCardPresentPaymentInLineMessageAnimation,
         connectCardReader: @escaping () -> Void) {
        self.animation = animation
        self.connectCardReader = connectCardReader
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

            Spacer()
                .frame(height: dynamicSpacing(PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing))

            Button {
                connectCardReader()
            } label: {
                Text(viewModel.connectReaderButtonTitle)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .frame(width: width * 0.5)
        }
        .frame(maxWidth: .infinity)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
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
        animation: .init(namespace: namespace),
        connectCardReader: {})
}
#endif
