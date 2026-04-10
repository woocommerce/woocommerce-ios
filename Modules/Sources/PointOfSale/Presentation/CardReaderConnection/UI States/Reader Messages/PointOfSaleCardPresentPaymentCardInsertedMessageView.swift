import SwiftUI

struct PointOfSaleCardPresentPaymentCardInsertedMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentCardInsertedMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isSubtitleFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .center, spacing: Constants.imageAndTextSpacing) {
            POSCardPresentPaymentMessageViewImage(imageName: viewModel.imageName)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
                .renderedIf(!dynamicTypeSize.isAccessibilitySize)
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.subtitle)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isSubtitleFocused)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .multilineTextAlignment(.center)
        .onAppear {
            isSubtitleFocused = true
        }
    }
}

private extension PointOfSaleCardPresentPaymentCardInsertedMessageView {
    enum Constants {
        static let imageAndTextSpacing: CGFloat = POSSpacing.xLarge
    }
}

#Preview {
    return PointOfSaleCardPresentPaymentCardInsertedMessageView(
        viewModel: PointOfSaleCardPresentPaymentCardInsertedMessageViewModel(),
        animation: .init(namespace: Namespace().wrappedValue)
    )
}
