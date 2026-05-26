import SwiftUI

struct PointOfSaleCardPresentPaymentActivityIndicatingMessageView: View {
    let title: String
    let message: String
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isMessageFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .center, spacing: Constants.imageAndTextSpacing) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
                .frame(width: Constants.headerDimension,
                       height: Constants.headerDimension)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
                .renderedIf(!dynamicTypeSize.isAccessibilitySize)
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(title)
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .font(.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(message)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isMessageFocused)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .multilineTextAlignment(.center)
        .onAppear {
            isMessageFocused = true
        }
    }
}

private extension PointOfSaleCardPresentPaymentActivityIndicatingMessageView {
    enum Constants {
        static let headerDimension: CGFloat = 160
        static let imageAndTextSpacing: CGFloat = POSSpacing.xLarge
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentActivityIndicatingMessageView(
        title: "Checking order",
        message: "Getting ready",
        animation: .init(namespace: namespace)
    )
}
