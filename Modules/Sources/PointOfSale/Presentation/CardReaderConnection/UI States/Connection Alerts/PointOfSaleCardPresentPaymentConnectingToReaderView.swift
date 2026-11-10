import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingToReaderView: View {
    @Environment(\.posMetrics) private var metrics
    private let viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel
    private let animation: POSCardPresentPaymentAlertAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool

    init(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel,
         animation: POSCardPresentPaymentAlertAnimation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        VStack(spacing: metrics.spacing.large) {
            Image(decorative: viewModel.imageName, bundle: .module)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            VStack(spacing: metrics.spacing.medium) {
                Text(viewModel.title)
                    .font(POSFontStyle.posHeadingBold)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.instruction)
                    .font(POSFontStyle.posBodyLargeRegular())
                    .fixedSize(horizontal: false, vertical: true)
                    .matchedGeometryEffect(id: animation.contentTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
        .onAppear {
            isTitleFocused = true
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentConnectingToReaderView(
        viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel(),
        animation: .init(namespace: namespace)
    )
}
