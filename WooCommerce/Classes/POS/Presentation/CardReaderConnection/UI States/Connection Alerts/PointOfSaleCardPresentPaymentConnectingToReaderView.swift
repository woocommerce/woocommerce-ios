import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingToReaderView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation

    init(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
            Image(decorative: viewModel.imageName)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                Text(viewModel.title)
                    .font(POSFontStyle.posTitleEmphasized)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.instruction)
                    .font(POSFontStyle.posBodyRegular)
                    .fixedSize(horizontal: false, vertical: true)
                    .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentConnectingToReaderView(
        viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel(),
        animation: .init(namespace: namespace)
    )
}
