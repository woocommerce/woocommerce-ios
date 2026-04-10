import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedNonRetryableView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel
    let animation: POSCardPresentPaymentAlertAnimation

    var body: some View {
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
        .posModalCloseButton(action: viewModel.cancelButtonViewModel.actionHandler,
                             accessibilityLabel: viewModel.cancelButtonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentConnectingFailedNonRetryableView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel(
            error: NSError(domain: "payments error", code: 1),
            cancelAction: {}),
        animation: .init(namespace: namespace)
    )
}
