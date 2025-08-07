import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingLocationPreAlertView: View {
    let viewModel: PointOfSaleCardPresentPaymentConnectingLocationPreAlertViewModel
    let animation: POSCardPresentPaymentAlertAnimation

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                    Text(viewModel.title)
                        .font(POSFontStyle.posHeadingBold)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                    VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                        Text(viewModel.subtitle)
                            .font(POSFontStyle.posBodyLargeRegular())
                            .fixedSize(horizontal: false, vertical: true)

                        Text(viewModel.detail)
                            .font(POSFontStyle.posBodyLargeRegular())
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
                }
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            Button(viewModel.primaryButtonViewModel.title,
                   action: viewModel.primaryButtonViewModel.actionHandler)
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @Namespace var namespace
    PointOfSaleCardPresentPaymentConnectingLocationPreAlertView(
        viewModel: PointOfSaleCardPresentPaymentConnectingLocationPreAlertViewModel(requestPermissionAction: {}),
        animation: .init(namespace: namespace)
    )
}
