import SwiftUI

struct PointOfSaleCardPresentPaymentCancelledOnReaderMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
            Text(viewModel.title)
                .font(.posHeading)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)
                .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentCancelledOnReaderMessageView(
        viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel(),
        animation: .init(namespace: namespace)
    )
}
