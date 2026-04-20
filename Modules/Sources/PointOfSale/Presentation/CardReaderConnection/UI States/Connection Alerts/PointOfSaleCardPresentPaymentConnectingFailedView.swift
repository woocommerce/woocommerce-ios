import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool

    init(viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName, bundle: .module)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                    Text(viewModel.title)
                        .font(POSFontStyle.posHeadingBold)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($isTitleFocused)
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
        .onAppear {
            isTitleFocused = true
        }
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
