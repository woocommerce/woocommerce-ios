import SwiftUI

struct PointOfSaleCardPresentPaymentConnectionSuccessAlertView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation

    init(viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
            Image(decorative: viewModel.imageName)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)
        }
        .posModalCloseButton(action: viewModel.buttonViewModel.actionHandler)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentConnectionSuccessAlertView(
        viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(doneAction: {}),
        animation: .init(namespace: namespace)
    )
}
