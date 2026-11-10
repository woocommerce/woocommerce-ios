import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentCaptureErrorMessageView: View {
    @Environment(\.posMetrics) private var metrics
    @StateObject private var viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State private var width: CGFloat = 0

    init(viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel, animation: POSCardPresentPaymentInLineMessageAnimation) {
        self._viewModel = .init(wrappedValue: viewModel)
        self.animation = animation
    }

    var body: some View {
        VStack(alignment: .center, spacing: metrics.spacing.none) {
            POSErrorXMark()
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            Spacer()
                .frame(height: metrics.spacing.large)

            VStack(alignment: .center, spacing: metrics.spacing.small) {
                Text(viewModel.title)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
                .frame(height: metrics.spacing.xxLarge)

            VStack(spacing: metrics.spacing.large) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                Button(action: viewModel.newOrderButtonViewModel.actionHandler) {
                    Label(viewModel.newOrderButtonViewModel.title, systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }
            .dynamicWidthScaling(containerWidth: width)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .posModal(isPresented: $viewModel.showsInfoSheet, compactStyle: .notMigratedFullScreen) {
            PointOfSaleCardPresentPaymentCaptureFailedView(isPresented: $viewModel.showsInfoSheet)
        }
        .onAppear {
            viewModel.onAppear()
            isTitleFocused = true
        }
        .measureWidth({ containerWidth in
            width = containerWidth
        })
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentCaptureErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel(
            tryAgainButtonAction: {},
            newOrderButtonAction: {}),
        animation: .init(namespace: namespace)
    )
    .environmentObject(POSModalManager())
}
