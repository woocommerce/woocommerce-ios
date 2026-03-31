import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName, bundle: .module)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.title)
                    .font(POSFontStyle.posHeadingBold)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)
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
    return PointOfSaleCardPresentPaymentReaderUpdateFailedView(
        viewModel: .init(retryAction: {}, cancelUpdateAction: {}),
        animation: .init(namespace: namespace)
    )
}
