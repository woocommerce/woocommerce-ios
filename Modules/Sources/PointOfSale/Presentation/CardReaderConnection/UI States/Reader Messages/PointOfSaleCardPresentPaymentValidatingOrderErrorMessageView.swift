import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation

    @State private var width: CGFloat = 0
    @Environment(\.posLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.none) {
            POSErrorExclamationMark(size: .large)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
            .padding(.horizontal, PointOfSaleCardPresentPaymentLayout.horizontalPadding)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

            if let tryAgainButtonViewModel = viewModel.tryAgainButtonViewModel {
                Button(tryAgainButtonViewModel.title, action: tryAgainButtonViewModel.actionHandler)
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
                    .if(layoutScale == .tablet) { $0.frame(width: width * 0.5) }
                    .if(layoutScale == .phone) { $0.frame(maxWidth: .infinity).padding(.horizontal, POSPadding.medium) }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
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
