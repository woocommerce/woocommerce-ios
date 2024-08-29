import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel
    let animation: POSCardPresentPaymentAlertAnimation

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
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
                        .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
                }
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            Button(viewModel.retryButtonViewModel.title,
                   action: viewModel.retryButtonViewModel.actionHandler)
            .buttonStyle(POSPrimaryButtonStyle())
            .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
        }
        .posModalCloseButton(action: viewModel.cancelButtonViewModel.actionHandler,
                              accessibilityLabel: viewModel.cancelButtonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel(
            retryButtonAction: {},
            cancelButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}
