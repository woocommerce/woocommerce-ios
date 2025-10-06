import SwiftUI

struct PointOfSaleCardPresentPaymentBluetoothRequiredAlertView: View {
    private let viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation

    init(viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel,
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

                    Text(viewModel.errorDetails)
                        .font(POSFontStyle.posBodyLargeRegular())
                        .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            Button(viewModel.openSettingsButtonViewModel.title,
                   action: viewModel.openSettingsButtonViewModel.actionHandler)
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
        }
        .scrollVerticallyIfNeeded()
        .posModalCloseButton(action: viewModel.dismissButtonViewModel.actionHandler,
                             accessibilityLabel: viewModel.dismissButtonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentBluetoothRequiredAlertView(
        viewModel: .init(error: NSError(domain: "", code: 1),
                         endSearch: {}),
        animation: .init(namespace: namespace)
    )
}
