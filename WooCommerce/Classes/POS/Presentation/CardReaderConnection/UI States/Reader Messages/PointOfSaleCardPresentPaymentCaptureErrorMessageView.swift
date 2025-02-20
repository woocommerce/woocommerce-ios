import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentCaptureErrorMessageView: View {
    @StateObject private var viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @State private var width: CGFloat = 0

    init(viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel, animation: POSCardPresentPaymentInLineMessageAnimation) {
        self._viewModel = .init(wrappedValue: viewModel)
        self.animation = animation
    }

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorXMark()
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .accessibilityAddTraits(.isHeader)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.smallTextSpacing) {
                    Text(viewModel.message)
                    Text(viewModel.nextStep)
                }
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurface)
                .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }

            VStack(spacing: PointOfSaleCardPresentPaymentLayout.buttonSpacing) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                Button(action: viewModel.newOrderButtonViewModel.actionHandler) {
                    Label(viewModel.newOrderButtonViewModel.title, systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }
            .frame(width: width * 0.5)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: PointOfSaleCardPresentPaymentLayout.errorContentMaxWidth)
        .posModal(isPresented: $viewModel.showsInfoSheet) {
            PointOfSaleCardPresentPaymentCaptureFailedView(isPresented: $viewModel.showsInfoSheet)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .measureWidth({ containerWidth in
            width = containerWidth
        })
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentCaptureErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel(
            tryAgainButtonAction: {},
            newOrderButtonAction: {}),
        animation: .init(namespace: namespace)
    )
    .environmentObject(POSModalManager())
}
