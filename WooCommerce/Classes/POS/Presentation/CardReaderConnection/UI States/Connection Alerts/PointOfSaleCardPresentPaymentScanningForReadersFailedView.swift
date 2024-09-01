import SwiftUI

struct PointOfSaleCardPresentPaymentScanningForReadersFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation

    init(viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel,
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

                Text(viewModel.errorDetails)
                    .font(POSFontStyle.posBodyRegular)
                    .fixedSize(horizontal: false, vertical: true)
                    .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .posModalCloseButton(action: viewModel.buttonViewModel.actionHandler,
                             accessibilityLabel: viewModel.buttonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentScanningForReadersFailedView(
        viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel(
            error: NSError(domain: "", code: 1, userInfo: nil),
            endSearchAction: {}),
        animation: .init(namespace: namespace))
}
