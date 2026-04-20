import SwiftUI

struct PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isMessageFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing) {
            ProgressView()
                .progressViewStyle(CardWaveProgressViewStyle())
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
                .accessibilityHidden(true)
                .renderedIf(!dynamicTypeSize.isAccessibilitySize)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundColor(.posOnPrimary)
                    .font(.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isMessageFocused)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .padding(.bottom)
        .multilineTextAlignment(.center)
        .onAppear {
            isMessageFocused = true
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView(
        viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(
            message: "Remove card"),
        animation: .init(namespace: Namespace().wrappedValue)
    )
    .background(Color.posPrimary)
}
