import Foundation

enum PointOfSaleCardPresentPaymentMessageType {
    case preparingForPayment(viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel)
    case tapSwipeOrInsertCard(viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel)
    case processing(viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel)
    case displayReaderMessage(viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel)
    case success(viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel)
    case error(viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel)
    case nonRetryableError(viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel)
    case cancelledOnReader(viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel)
}
