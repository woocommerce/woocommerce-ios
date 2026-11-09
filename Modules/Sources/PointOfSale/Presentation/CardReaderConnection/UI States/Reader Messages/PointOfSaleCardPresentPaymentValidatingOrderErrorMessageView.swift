import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView: View {
    @Environment(\.posMetrics) private var metrics
    let viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(alignment: .center, spacing: metrics.spacing.none) {
            POSErrorExclamationMark(size: .large)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            Spacer()
                .frame(height: metrics.spacing.large)

            VStack(alignment: .center, spacing: metrics.spacing.small) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
            .padding(.horizontal, metrics.padding.xxLarge)

            Spacer()
                .frame(height: metrics.spacing.xxLarge)

            if let tryAgainButtonViewModel = viewModel.tryAgainButtonViewModel {
                Button(tryAgainButtonViewModel.title, action: tryAgainButtonViewModel.actionHandler)
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
                    .posStatusButtonsWidth()
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .onAppear {
            isTitleFocused = true
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            retryApproach: .tryAgain(retryAction: {})),
        animation: .init(namespace: namespace)
    )
}
