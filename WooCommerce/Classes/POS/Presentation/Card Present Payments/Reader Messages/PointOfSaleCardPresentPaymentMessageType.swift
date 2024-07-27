import Foundation

enum PointOfSaleCardPresentPaymentMessageType {
    case validatingOrder(viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel)
    case preparingForPayment(viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel)
    case tapSwipeOrInsertCard(viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel)
    case processing(viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel)
    case displayReaderMessage(viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel)
    case paymentSuccess(viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel)
    case paymentError(viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel)
    case paymentErrorNonRetryable(viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel)
    case paymentCaptureError(viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel)
    case cancelledOnReader(viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel)
}
