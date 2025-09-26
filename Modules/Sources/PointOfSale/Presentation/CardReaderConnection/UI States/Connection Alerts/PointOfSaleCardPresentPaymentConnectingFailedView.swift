import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation

    init(viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName, bundle: .module)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                    Text(viewModel.title)
                        .font(POSFontStyle.posHeadingBold)
                        .accessibilityAddTraits(.isHeader)
                        .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                    if let errorDetails = viewModel.errorDetails {
                        Text(errorDetails)
                            .font(POSFontStyle.posBodyLargeRegular())
                            .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            Button(viewModel.retryButtonViewModel.title,
                   action: viewModel.retryButtonViewModel.actionHandler)
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
        }
        .scrollVerticallyIfNeeded()
        .posModalCloseButton(action: viewModel.cancelButtonViewModel.actionHandler,
                             accessibilityLabel: viewModel.cancelButtonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentConnectingFailedView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel(
            error: NSError(domain: "preview.error", code: 1),
            retryButtonAction: {},
            cancelButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}
