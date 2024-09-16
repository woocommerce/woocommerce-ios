import SwiftUI

struct PointOfSaleCardPresentPaymentInLineMessage: View {
    private let messageType: PointOfSaleCardPresentPaymentMessageType

    init(messageType: PointOfSaleCardPresentPaymentMessageType) {
        self.messageType = messageType
    }

    var body: some View {
        switch messageType {
        case .validatingOrder(let viewModel):
            PointOfSaleCardPresentPaymentActivityIndicatingMessageView(title: viewModel.title, message: viewModel.message, animation: animation)
        case .validatingOrderError(let viewModel):
            PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView(viewModel: viewModel, animation: animation)
        case .preparingForPayment(let viewModel):
            PointOfSaleCardPresentPaymentActivityIndicatingMessageView(title: viewModel.title, message: viewModel.message, animation: animation)
        case .tapSwipeOrInsertCard(let viewModel):
            PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView(viewModel: viewModel, animation: animation)
        case .processing(let viewModel):
            PointOfSaleCardPresentPaymentProcessingMessageView(viewModel: viewModel, animation: animation)
        case .displayReaderMessage(let viewModel):
            PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView(viewModel: viewModel, animation: animation)
        case .paymentSuccess(let viewModel):
            PointOfSaleCardPresentPaymentSuccessMessageView(viewModel: viewModel, animation: animation)
        case .paymentError(let viewModel):
            PointOfSaleCardPresentPaymentErrorMessageView(viewModel: viewModel, animation: animation)
        case .paymentErrorNonRetryable(let viewModel):
            PointOfSaleCardPresentPaymentNonRetryableErrorMessageView(viewModel: viewModel, animation: animation)
        case .paymentCaptureError(let viewModel):
            PointOfSaleCardPresentPaymentCaptureErrorMessageView(viewModel: viewModel, animation: animation)
        case .cancelledOnReader(let viewModel):
            PointOfSaleCardPresentPaymentCancelledOnReaderMessageView(viewModel: viewModel, animation: animation)
        }
    }

    // MARK: - Animations

    /// Used together with .matchedGeometryEffect
    /// This makes SwiftUI treat different messages as a single view in the context of animation.
    /// Allows to smoothly transition from one view to another while also transitioning to full-screen
    @Namespace private var namespace
    private var animation: POSCardPresentPaymentInLineMessageAnimation { .init(namespace: namespace) }
}

#Preview {
    PointOfSaleCardPresentPaymentInLineMessage(messageType: .processing(
        viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel()))
}

struct POSCardPresentPaymentInLineMessageAnimation {
    let namespace: Namespace.ID
    let iconTransitionId: String = "pos_card_present_payment_in_line_message_icon_matched_geometry_id"
    let titleTransitionId: String = "pos_card_present_payment_in_line_message_title_matched_geometry_id"
    let messageTransitionId: String = "pos_card_present_payment_in_line_message_message_matched_geometry_id"
}
