import Foundation

enum PointOfSaleCardPresentPaymentMessageType: Equatable {
    case validatingOrder(viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel)
    case validatingOrderError(viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel)
    case preparingForPayment(viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel)
    case tapSwipeOrInsertCard(viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel)
    case cardInserted(viewModel: PointOfSaleCardPresentPaymentCardInsertedMessageViewModel)
    case processing(viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel)
    case displayReaderMessage(viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel)
    case paymentSuccess(viewModel: PointOfSalePaymentSuccessViewModel)
    case paymentError(viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel)
    case paymentErrorNonRetryable(viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel)
    case paymentCaptureError(viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel)
    case paymentIntentCreationError(viewModel: PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel)
    case cancelledOnReader(viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel)
    case paymentCancellationConfirmation(viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel)
}

extension PointOfSaleCardPresentPaymentMessageType {
    /// Messages shown as a status screen, with their buttons pinned to the bottom.
    /// Order validation and payment intent errors stay inline above the order totals.
    var isStatusScreen: Bool {
        switch self {
        case .paymentSuccess,
                .paymentError,
                .paymentErrorNonRetryable,
                .paymentCaptureError,
                .cancelledOnReader,
                .paymentCancellationConfirmation:
            return true
        case .validatingOrder,
                .validatingOrderError,
                .paymentIntentCreationError,
                .preparingForPayment,
                .tapSwipeOrInsertCard,
                .cardInserted,
                .processing,
                .displayReaderMessage:
            return false
        }
    }
}
