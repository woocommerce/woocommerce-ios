import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView: View {
    @Environment(\.posMetrics) private var metrics
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: metrics.spacing.large) {
                Image(decorative: viewModel.imageName, bundle: .module)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.title)
                    .font(POSFontStyle.posHeadingBold)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)
            }

            Spacer(minLength: metrics.spacing.large)

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
        }
        .frame(maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
        .posModalFlowHeaderCloseButton(action: viewModel.cancelButtonViewModel.actionHandler)
        .onAppear {
            isTitleFocused = true
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView(
        viewModel: .init(cancelUpdateAction: {}),
        animation: .init(namespace: namespace)
    )
}
