import SwiftUI

struct POSRefundCardPresentMessageView: View {
    let messageType: POSRefundCardPresentMessageType
    let animation: POSCardPresentPaymentInLineMessageAnimation

    var body: some View {
        switch messageType {
        case .preparingReader(let viewModel):
            PointOfSaleCardPresentPaymentActivityIndicatingMessageView(title: viewModel.title,
                                                                       message: viewModel.message,
                                                                       animation: animation)
        case .waitingForCard(let viewModel),
                .cardInserted(let viewModel):
            POSRefundCardPresentImageMessageView(viewModel: viewModel, animation: animation)
        case .processing(let viewModel),
                .displayReaderMessage(let viewModel):
            POSRefundCardPresentProcessingMessageView(viewModel: viewModel, animation: animation)
        case .cancelledOnReader(let viewModel):
            POSRefundCardPresentActionMessageView(viewModel: viewModel, animation: animation)
        case .error(let viewModel):
            POSRefundCardPresentErrorMessageView(viewModel: viewModel, animation: animation)
        }
    }
}

private struct POSRefundCardPresentImageMessageView: View {
    let viewModel: POSRefundCardPresentImageMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isMessageFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.xLarge) {
            POSCardPresentPaymentMessageViewImage(imageName: viewModel.imageName)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
                .renderedIf(!dynamicTypeSize.isAccessibilitySize)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .font(.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isMessageFocused)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityIdentifier("pos-card-refund-message")
        .onAppear {
            isMessageFocused = true
        }
    }
}

private struct POSRefundCardPresentProcessingMessageView: View {
    let viewModel: POSRefundCardPresentProcessingMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isMessageFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing) {
            ProgressView()
                .progressViewStyle(CardWaveProgressViewStyle())
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
                .accessibilityHidden(true)
                .renderedIf(!dynamicTypeSize.isAccessibilitySize)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundColor(.posOnPrimary)
                    .font(.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.message)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isMessageFocused)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .padding(.bottom)
        .multilineTextAlignment(.center)
        .onAppear {
            isMessageFocused = true
        }
    }
}

private struct POSRefundCardPresentActionMessageView: View {
    let viewModel: POSRefundCardPresentActionMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation

    var body: some View {
        POSRefundCardPresentActionContent(title: viewModel.title,
                                          message: viewModel.message,
                                          primaryButtonViewModel: viewModel.primaryButtonViewModel,
                                          secondaryButtonViewModel: viewModel.secondaryButtonViewModel,
                                          animation: animation)
    }
}

private struct POSRefundCardPresentErrorMessageView: View {
    let viewModel: POSRefundCardPresentErrorMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation

    var body: some View {
        POSRefundCardPresentActionContent(title: viewModel.title,
                                          message: viewModel.message,
                                          primaryButtonViewModel: viewModel.primaryButtonViewModel,
                                          secondaryButtonViewModel: viewModel.secondaryButtonViewModel,
                                          animation: animation)
    }
}

private struct POSRefundCardPresentActionContent: View {
    let title: String
    let message: String?
    let primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel?
    let secondaryButtonViewModel: CardPresentPaymentsModalButtonViewModel?
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.none) {
            Spacer()

            POSErrorXMark()
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(title)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                if let message {
                    Text(message)
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurface)
                        .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
                }
            }
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

            VStack(spacing: PointOfSaleCardPresentPaymentLayout.buttonSpacing) {
                if let primaryButtonViewModel {
                    Button(primaryButtonViewModel.title,
                           action: primaryButtonViewModel.actionHandler)
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
                }

                if let secondaryButtonViewModel {
                    Button(secondaryButtonViewModel.title,
                           action: secondaryButtonViewModel.actionHandler)
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                }
            }
            .dynamicWidthScaling(containerWidth: width)

            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .measureWidth { containerWidth in
            width = containerWidth
        }
        .onAppear {
            isTitleFocused = true
        }
    }
}
