import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentIntentCreationErrorMessageView: View {
    @Environment(\.posMetrics) private var metrics
    let viewModel: PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(alignment: .center, spacing: metrics.spacing.none) {
            POSErrorXMark()
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
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }

            Spacer()
                .frame(height: metrics.spacing.xxLarge)

            VStack(spacing: metrics.spacing.large) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                if let editOrderButtonViewModel = viewModel.editOrderButtonViewModel {
                    Button(editOrderButtonViewModel.title,
                           action: editOrderButtonViewModel.actionHandler)
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                }
            }
            .minimumScaleFactor(1)
            .dynamicWidthScaling(containerWidth: width)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
        .onAppear {
            isTitleFocused = true
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace

    return PointOfSaleCardPresentPaymentIntentCreationErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            tryPaymentAgainButtonAction: {},
            editOrderButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}
