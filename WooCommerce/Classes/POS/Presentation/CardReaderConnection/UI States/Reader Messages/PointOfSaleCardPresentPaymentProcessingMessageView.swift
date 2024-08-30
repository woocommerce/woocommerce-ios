import SwiftUI

struct PointOfSaleCardPresentPaymentProcessingMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation

    var body: some View {
        VStack(alignment: .center, spacing: Layout.headerSpacing) {
            ProgressView()
                .progressViewStyle(CardWaveProgressViewStyle())
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            VStack(alignment: .center, spacing: Layout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(.white)
                    .font(.posBodyRegular)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(Color.posDarkGray.opacity(0.16))
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .padding(.bottom)
        .multilineTextAlignment(.center)
        .transition(.asymmetric(insertion: .identity, removal: .opacity))
    }
}

private extension PointOfSaleCardPresentPaymentProcessingMessageView {
    enum Layout {
        static let headerSpacing: CGFloat = 48
        static let textSpacing: CGFloat = 16
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentProcessingMessageView(
        viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel(),
        animation: .init(namespace: namespace)
    )
}
