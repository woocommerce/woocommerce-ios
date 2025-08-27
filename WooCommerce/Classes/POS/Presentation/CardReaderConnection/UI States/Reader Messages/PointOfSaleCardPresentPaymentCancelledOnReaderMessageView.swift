import SwiftUI

struct PointOfSaleCardPresentPaymentCancelledOnReaderMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.none) {
            Spacer()

            POSErrorXMark()
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)
            }
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

            VStack(spacing: PointOfSaleCardPresentPaymentLayout.buttonSpacing) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))
            }
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentCancelledOnReaderMessageView(
        viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel(tryPaymentAgainButtonAction: {}),
        animation: .init(namespace: namespace)
    )
}
