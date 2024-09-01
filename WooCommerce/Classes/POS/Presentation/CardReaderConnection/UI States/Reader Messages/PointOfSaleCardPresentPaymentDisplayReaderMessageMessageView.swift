import SwiftUI

struct PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation

    var body: some View {
        VStack(alignment: .center, spacing: Layout.headerSpacing) {
            ProgressView()
                .progressViewStyle(CardWaveProgressViewStyle())
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: Layout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(.white)
                    .font(.posBodyRegular)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .padding(.bottom)
        .multilineTextAlignment(.center)
    }
}

private extension PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView {
    enum Layout {
        static let headerSpacing: CGFloat = 48
        static let textSpacing: CGFloat = 16
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView(
        viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(
            message: "Remove card"),
        animation: .init(namespace: namespace)
    )
}
