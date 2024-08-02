import SwiftUI

struct PointOfSaleCardPresentPaymentInLineMessage: View {
    private let messageType: PointOfSaleCardPresentPaymentMessageType

    init(messageType: PointOfSaleCardPresentPaymentMessageType) {
        self.messageType = messageType
    }

    var body: some View {

        // TODO: replace temporary inline message UI based on design
        switch messageType {
        case .validatingOrder(let viewModel):
            PointOfSaleCardPresentPaymentActivityIndicatingMessageView(title: viewModel.title, message: viewModel.message)
        case .preparingForPayment(let viewModel):
            PointOfSaleCardPresentPaymentActivityIndicatingMessageView(title: viewModel.title, message: viewModel.message)
        case .tapSwipeOrInsertCard(let viewModel):
            PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView(viewModel: viewModel)
                .matchedGeometryEffect(id: Self.transitionAnimationId, in: transitionAnimation)
        case .processing(let viewModel):
            PointOfSaleCardPresentPaymentProcessingMessageView(viewModel: viewModel)
                .matchedGeometryEffect(id: Self.transitionAnimationId, in: transitionAnimation)
        case .displayReaderMessage(let viewModel):
            PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView(viewModel: viewModel)
                .matchedGeometryEffect(id: Self.transitionAnimationId, in: transitionAnimation)
        case .paymentSuccess(let viewModel):
            PointOfSaleCardPresentPaymentSuccessMessageView(viewModel: viewModel)
        case .paymentError(let viewModel):
            PointOfSaleCardPresentPaymentErrorMessageView(viewModel: viewModel)
        case .paymentErrorNonRetryable(let viewModel):
            PointOfSaleCardPresentPaymentNonRetryableErrorMessageView(viewModel: viewModel)
        case .paymentCaptureError(let viewModel):
            PointOfSaleCardPresentPaymentCaptureErrorMessageView(viewModel: viewModel)
        case .cancelledOnReader(let viewModel):
            PointOfSaleCardPresentPaymentCancelledOnReaderMessageView(viewModel: viewModel)
        }
    }

    // MARK: - Animations

    /// Used together with .matchedGeometryEffect
    /// This makes SwiftUI treat different messages as a single view in the context of animation.
    /// Allows to smoothly transition from one view to another while also transitioning to full-screen
    @Namespace private var transitionAnimation
    private static let transitionAnimationId = "pos_card_present_payment_in_line_message_matched_geometry_id"
}

#Preview {
    PointOfSaleCardPresentPaymentInLineMessage(messageType: .processing(
        viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel()))
}
