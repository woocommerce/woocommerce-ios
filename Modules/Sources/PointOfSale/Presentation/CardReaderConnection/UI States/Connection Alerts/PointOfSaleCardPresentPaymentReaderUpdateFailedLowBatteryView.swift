import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
            Spacer()
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName, bundle: .module)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                    Text(viewModel.title)
                        .font(POSFontStyle.posHeadingBold)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                    Text(viewModel.batteryLevelInfo)
                        .font(POSFontStyle.posBodyLargeRegular())
                        .fixedSize(horizontal: false, vertical: true)
                        .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
                }
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()


            VStack(spacing: PointOfSaleReaderConnectionModalLayout.buttonSpacing) {
                Button(viewModel.retrySearchButtonViewModel.title,
                       action: viewModel.retrySearchButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                Button(viewModel.cancelButtonViewModel.title,
                       action: viewModel.cancelButtonViewModel.actionHandler)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }
            .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryView(
        viewModel: .init(batteryLevel: nil, retrySearchAction: {}, cancelUpdateAction: {}),
        animation: .init(namespace: namespace)
    )
}
