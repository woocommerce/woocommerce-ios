import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel
    let animation: POSCardPresentPaymentAlertAnimation

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName, bundle: .module)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                    Text(viewModel.title)
                        .font(POSFontStyle.posHeadingBold)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                    Text(viewModel.errorDetails)
                        .font(POSFontStyle.posBodyLargeRegular())
                        .fixedSize(horizontal: false, vertical: true)
                        .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
                }
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            Spacer(minLength: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing)

            Button(viewModel.retryButtonViewModel.title,
                   action: viewModel.retryButtonViewModel.actionHandler)
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
        }
        .frame(maxHeight: .infinity)
        .posModalCloseButton(action: viewModel.cancelButtonViewModel.actionHandler,
                              accessibilityLabel: viewModel.cancelButtonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel(
            retryButtonAction: {},
            cancelButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}
